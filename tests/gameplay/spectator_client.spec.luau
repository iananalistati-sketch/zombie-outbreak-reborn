-- Executes actual camera ownership, filtering, cycling and cleanup logic.
local Policy=assert(loadstring(POLICY_SOURCE))()
local checks=0
local function check(v,label)assert(v,label);checks+=1 end
local function signal()
    local handlers={}
    return {Connect=function(_,fn)local c={};handlers[c]=fn;function c:Disconnect()handlers[self]=nil end;return c end,
        Fire=function(_,...)for _,fn in table.clone(handlers)do fn(...)end end}
end
local methods={}
local function object(class,name,parent)
    local data={ClassName=class,Name=name or class,children={},attrs={}}
    local obj
    obj=setmetatable({data=data},{__index=function(_,k)return methods[k] or data[k] or data.children[k]end,
        __newindex=function(_,k,v)
            if k=='Parent' then
                if data.Parent then data.Parent.data.children[data.Name]=nil end
                data.Parent=v;if v then v.data.children[data.Name]=obj end
            else data[k]=v end
        end})
    obj.Destroying=signal();obj.Activated=signal();if parent then obj.Parent=parent end;return obj
end
function methods:GetChildren()local list={};for _,v in self.data.children do table.insert(list,v)end;return list end
function methods:FindFirstChild(n)return self.data.children[n]end
function methods:WaitForChild(n)return assert(self:FindFirstChild(n),n)end
function methods:FindFirstChildOfClass(c)for _,v in self.data.children do if v.ClassName==c then return v end end end
function methods:IsDescendantOf(p)local v=self.Parent;while v do if v==p then return true end;v=v.Parent end;return false end
function methods:GetAttribute(n)return self.data.attrs[n]end
function methods:SetAttribute(n,v)self.data.attrs[n]=v end
function methods:Clone()
    local copy=object(self.ClassName,self.Name)
    for k,v in self.data do if k~='children' and k~='attrs' and k~='Parent' then copy[k]=v end end
    return copy
end
function methods:Destroy()self.Destroying:Fire();for _,v in table.clone(self.data.children)do v:Destroy()end;self.Parent=nil end
local now=10
local world=object('Workspace','Workspace');function world:GetServerTimeNow()return now end
local camera=object('Camera','Camera');camera.CameraType='Custom';camera.ViewportSize={X=1280,Y=720};world.CurrentCamera=camera
local function actor(id,role)
    local p=object('Player','P'..id);p.UserId=id;p.DisplayName='Player '..id;p.Team={Name=role}
    local char=object('Model','C'..id,world);p.Character=char
    local h=object('Humanoid','Humanoid',char);h.Health=100
    object('Part','HumanoidRootPart',char)
    return p,h
end
local player,own=actor(1,'Zombies');player.CameraMinZoomDistance=.5;player.CameraMaxZoomDistance=128
local pg=object('PlayerGui','PlayerGui',player)
local zombieA,zhA=actor(2,'Zombies');local zombieB,zhB=actor(3,'Zombies');local human,hh=actor(4,'Humans')
local list={player,zombieA,zombieB,human}
camera.CameraSubject=own
local players={LocalPlayer=player,GetPlayers=function()return table.clone(list)end}
local rs=object('ReplicatedStorage','ReplicatedStorage');rs:SetAttribute('ZO_RoundState','Active')
local shared=object('Folder','K17Gameplay',rs);local token=object('ModuleScript','SpectatorState',shared)
local actions,bindings={},{ }
local cas={BindActionAtPriority=function(_,name,callback)actions[name]=callback end,UnbindAction=function(_,name)actions[name]=nil end}
local run={BindToRenderStep=function(_,name,priority,fn)bindings[name]=fn end,UnbindFromRenderStep=function(_,name)bindings[name]=nil end}
local services={Players=players,ReplicatedStorage=rs,RunService=run,ContextActionService=cas,UserInputService={GetFocusedTextBox=function()return nil end}}
local enum=setmetatable({RenderPriority={Camera={Value=100}}},{__index=function()return setmetatable({},{__index=function(_,k)return k end})end})
local function dim(xs,xo,ys,yo)return {X={Scale=xs or 0,Offset=xo or 0},Y={Scale=ys or 0,Offset=yo or 0}}end
local env=setmetatable({game={GetService=function(_,n)return assert(services[n],n)end},workspace=world,
    Instance={new=function(c)return object(c)end},Enum=enum,Vector2={new=function(x,y)return {X=x,Y=y}end},
    UDim={new=function(s,o)return {Scale=s,Offset=o}end},UDim2={new=dim,fromOffset=function(x,y)return dim(0,x,0,y)end},
    Color3={fromRGB=function(...)return {...}end},require=function(m)assert(m==token);return Policy end},{__index=getfenv()})
local fn=assert(loadstring(CLIENT_SOURCE));setfenv(fn,env);fn()
local function step(dt)dt=dt or .11;now+=dt;for _,f in table.clone(bindings)do f(dt)end end
local gui=assert(pg.ZO_SpectatorHUD);local panel=gui.Observer
step();check(not panel.Visible and camera.CameraSubject==own,'living combatant retains camera')
player:SetAttribute('ZO_SpawnPending',true);step()
check(panel.Visible and camera.CameraSubject==zhA and panel.Hint.Text:find('espaço seguro',1,true)~=nil,'queued live avatar keeps teammate observation with safe return message')
zombieA:SetAttribute('ZO_SpawnPending',true);step()
check(camera.CameraSubject==zhB,'queued teammate cannot become a spectator target')
zombieA:SetAttribute('ZO_SpawnPending',nil);player:SetAttribute('ZO_SpawnPending',nil);step()
check(not panel.Visible and camera.CameraSubject==own,'safe return restores own camera after pending wait')
camera.CameraType='Scriptable';step();camera.CameraType='Custom'
own.Health=0;player:SetAttribute('ZO_RespawnAt',now+5);step()
check(panel.Visible and camera.CameraSubject==zhA and player:GetAttribute('ZO_Spectating'),'death starts observation of live teammate')
check(player.CameraMinZoomDistance==8 and player.CameraMaxZoomDistance==20,'spectator uses a readable third-person range')
check(panel.Hint.Text:find('5s',1,true)~=nil,'server deadline drives respawn countdown')
actions.ZO_SpectatorCycle(nil,'Begin',{KeyCode='Right'});step()
check(camera.CameraSubject==zhB,'cycle selects next eligible teammate')
panel.Previous.Activated:Fire();step();check(camera.CameraSubject==zhA,'screen controls cycle backward')
zhA.Health=0;step();check(camera.CameraSubject==zhB,'dead target is replaced by another live teammate')
zhB.Health=0;step();check(panel.Target.Text=='Aguardando companheiro vivo' and camera.CameraSubject==own,'empty side never falls back to a living enemy')
zhA.Health=100;step();check(camera.CameraSubject==zhA,'newly available target resumes observation')
rs:SetAttribute('ZO_RoundState','Results');step()
check(not panel.Visible and camera.CameraSubject==own and player.CameraMinZoomDistance==.5 and player.CameraMaxZoomDistance==128,'results restore camera and zoom')
rs:SetAttribute('ZO_RoundState','Active');own.Health=100;player.Team={Name='Lobby'};step()
check(camera.CameraSubject==zhA,'late lobby spectator observes zombies instead of human refuges')
player.Team={Name='Humans'};step();check(camera.CameraSubject==own and not panel.Visible,'joining playable human role exits spectator')
player.Team={Name='Zombies'};own.Health=0;step()
local replacement=object('Camera','NewCamera');replacement.CameraType='Custom';replacement.ViewportSize={X=640,Y=480};replacement.CameraSubject=own
world.CurrentCamera=replacement;step()
check(camera.CameraSubject==own and replacement.CameraSubject==zhA,'camera replacement releases old camera and binds new one')
replacement.CameraType='Scriptable';step()
check(replacement.CameraSubject==zhA and not panel.Visible,'scripted camera takeover is preserved')
replacement.CameraType='Custom';step();check(not panel.Visible,'released ownership does not fight another camera each frame')
own.Health=100;step();own.Health=0;step()
check(panel.Visible and replacement.CameraSubject==zhA,'new life cycle can enter spectator again')
local external=object('Humanoid','CutsceneSubject');replacement.CameraSubject=external;player.CameraMinZoomDistance=2;player.CameraMaxZoomDistance=6;step()
check(replacement.CameraSubject==external and player.CameraMinZoomDistance==2,'external subject and zoom changes retain ownership')
own.Health=100;step();player.CameraMinZoomDistance=.5;player.CameraMaxZoomDistance=128;own.Health=0;step()
gui:Destroy();step()
check(not player:GetAttribute('ZO_Spectating') and bindings.ZO_SpectatorCamera==nil and actions.ZO_SpectatorCycle==nil,'teardown releases camera bindings and combat guard')
check(hh.Health==100 and human.Team.Name=='Humans','observer never mutates another player health or role')
print(('PASS actual spectator controller: %d checks; camera API doubles, no engine rendering'):format(checks))
