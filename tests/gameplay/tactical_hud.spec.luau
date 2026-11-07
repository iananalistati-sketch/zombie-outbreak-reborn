-- Executes the actual HUD across spawning, reports, scoreboard and teardown.
-- GUI/character services are doubles; rendering and screen overlap need Studio.
local State=assert(loadstring(STATE_SOURCE))()
local Config=assert(loadstring(CONFIG_SOURCE))()
local checks=0
local function check(v,label)assert(v,label);checks+=1 end
local function signal()
    local handlers={}
    return {Connect=function(_,fn)
        local c={};handlers[c]=fn;function c:Disconnect()handlers[self]=nil end;return c
    end,Fire=function(_,...)for _,fn in table.clone(handlers)do fn(...)end end}
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
    obj.Destroying=signal();obj.Activated=signal()
    if parent then obj.Parent=parent end
    return obj
end
function methods:FindFirstChild(n)return self.data.children[n]end
function methods:WaitForChild(n)return self:FindFirstChild(n)end
function methods:FindFirstChildOfClass(c)for _,v in self.data.children do if v.ClassName==c then return v end end end
function methods:GetAttribute(n)return self.data.attrs[n]end
function methods:SetAttribute(n,v)self.data.attrs[n]=v end
function methods:Destroy()self.Destroying:Fire();for _,c in table.clone(self.data.children)do c:Destroy()end;self.Parent=nil end
function methods:GetChildren()local a={};for _,c in self.data.children do table.insert(a,c)end;return a end
function methods:FindFirstAncestorOfClass(c)local p=self.Parent;while p do if p.ClassName==c then return p end;p=p.Parent end end
local vm={}
local function vec(x,y,z)return setmetatable({X=x,Y=y,Z=z},vm)end
vm.__sub=function(a,b)return vec(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
vm.__mul=function(a,b)return vec(a.X*b,a.Y*b,a.Z*b)end
vm.__index=function(v,k)if k=='Magnitude'then return math.sqrt(v.X^2+v.Y^2+v.Z^2)end end
local now=0
local rs=object('ReplicatedStorage','ReplicatedStorage')
local shared=object('Folder','K17Gameplay',rs)
local moduleMap={}
moduleMap[object('ModuleScript','TacticalState',shared)]=State
moduleMap[object('ModuleScript','Config',shared)]=Config
moduleMap[object('ModuleScript','EscapeConfig',shared)]={Stages={{Label='Gerador'},{Label='Bombas'},{Label='Terminal'}}}
moduleMap[object('ModuleScript','RouteGuide',shared)]=assert(loadstring(GUIDE_SOURCE))()
moduleMap[object('ModuleScript','WeaponHandling',shared)]=assert(loadstring(HANDLING_SOURCE))()
moduleMap[object('ModuleScript','RoundStats',shared)]=assert(loadstring(ROUND_STATS_SOURCE))()
moduleMap[object('ModuleScript','K17Refuges',rs)]={}
local remote=object('RemoteEvent','ZO_CombatFX',rs);remote.OnClientEvent=signal()
local world=object('Workspace','Workspace')
function world:GetServerTimeNow()return now end
local rayHit=nil;function world:Raycast()return rayHit end
local camera=object('Camera','Camera');camera.ViewportSize={X=1280,Y=720};world.CurrentCamera=camera
function camera:ViewportPointToRay()return {Origin=vec(0,4,0),Direction=vec(0,0,-1)}end
local player=object('Player','Player');player.DisplayName='Player';player.UserId=1;player.Team={Name='Humans'}
player.CharacterAdded=signal();player.CharacterRemoving=signal()
local playerGui=object('PlayerGui','PlayerGui',player)
local second=object('Player','Other');second.DisplayName='Other';second.UserId=2;second.Team={Name='Zombies'}
local list={player,second}
local players={LocalPlayer=player,GetPlayers=function()return table.clone(list)end}
local render=signal();local focus=signal()
local uis={WindowFocusReleased=focus,TouchEnabled=false,GetFocusedTextBox=function()return nil end}
local actions={}
local cas={BindActionAtPriority=function(_,name,callback)actions[name]=callback end,UnbindAction=function(_,name)actions[name]=nil end}
local services={Players=players,ReplicatedStorage=rs,RunService={RenderStepped=render},UserInputService=uis,
    ContextActionService=cas,StarterGui={SetCoreGuiEnabled=function()end}}
local enum=setmetatable({},{__index=function(_,group)return setmetatable({},{__index=function(_,key)return key end})end})
local function dim(xs,xo,ys,yo)return {X={Scale=xs or 0,Offset=xo or 0},Y={Scale=ys or 0,Offset=yo or 0}}end
local env=setmetatable({game={GetService=function(_,n)return assert(services[n],n)end},workspace=world,
    Instance={new=function(c)return object(c)end},Enum=enum,
    UDim2={new=dim,fromOffset=function(x,y)return dim(0,x,0,y)end,fromScale=function(x,y)return dim(x,0,y,0)end},
    UDim={new=function(s,o)return {Scale=s,Offset=o}end},Vector2={new=function(x,y)return{X=x,Y=y}end},
    Vector3={new=vec},
    Color3={fromRGB=function(r,g,b)return{R=r,G=g,B=b}end},RaycastParams={new=function()return{}end},
    task={spawn=function(fn,...)fn(...)end,wait=function()end},os={clock=function()return now end},
    require=function(m)return assert(moduleMap[m],'Unknown HUD dependency')end},{__index=getfenv()})
local fn=assert(loadstring(HUD_SOURCE));setfenv(fn,env);fn()
local gui=playerGui:FindFirstChild('ZO_RoundHUD')
local function tick(dt)now+=dt or .11;render:Fire(dt or .11)end
local function get(...)local node=gui;for _,name in {...}do node=assert(node:FindFirstChild(name),name)end;return node end
tick()
check(not get('Vitals').Visible,'loading without a Humanoid does not expose nil GUI state')
check(player:GetAttribute('ZO_TacticalHUDReady')==true,'first successful HUD projection publishes fallback handoff')
local function spawn()
    local char=object('Model','Character',world)
    local hum=object('Humanoid','Humanoid',char);hum.Health=100;hum.MaxHealth=100;hum.HealthChanged=signal()
    local root=object('Part','HumanoidRootPart',char);root.Position=vec(-68,4,-136)
    player.Character=char;player.CharacterAdded:Fire(char);return char,hum,root
end
local char,hum,root=spawn()
rs:SetAttribute('ZO_RoundState','Training');rs:SetAttribute('ZO_TrainingStage','Fighting');rs:SetAttribute('ZO_Version','0.2.0')
player:SetAttribute('ZO_Ammo',30);player:SetAttribute('ZO_Reserve',120);tick()
check(get('Vitals').Visible and get('Equipment','Ammunition').Text=='30 / 120','live solo projects health and server ammunition')
check(get('Location').Text=='Administração','location uses actual character coordinates')
check(get('PhaseAnnouncement').Visible,'phase change produces a temporary announcement')
tick(3.1);check(not get('PhaseAnnouncement').Visible,'announcement expires without blocking play')
hum.Health=20;hum.HealthChanged:Fire(20);tick(.01)
check(get('DamageEdge1').Visible,'taking damage produces local visual feedback')
hum.Health=100;hum.HealthChanged:Fire(100);tick(1)
check(not get('DamageEdge1').Visible,'damage feedback clears after recovery')
player:SetAttribute('ZO_Reloading',true);player:SetAttribute('ZO_ReloadEndsAt',now+1.2);tick()
check(get('Equipment','ReloadProgress').Visible,'reload shows progress from the server deadline')
player:SetAttribute('ZO_Reloading',false);tick()
check(not get('Equipment','ReloadProgress').Visible,'cancelling reload clears progress')
remote.OnClientEvent:Fire('Report',{Kind='Elimination',Actor='Player',ActorId=1,Victim='Infectado',Weapon='Rifle',Head=true});tick()
check(get('CombatReport1').Text:find('CABEÇA',1,true)~=nil,'confirmed report reaches the HUD')
tick(6.1);check(get('CombatReport1').Text=='','expired feed entries clear the screen')
actions.ZO_Scoreboard(nil,'Begin');tick(.5)
check(get('SessionScoreboard').Visible and player:GetAttribute('ZO_ScoreboardOpen'),'holding scoreboard key opens it and suspends weapon input')
check(#get('SessionScoreboard','Players'):GetChildren()==3,'scoreboard creates one row per player plus layout')
list[2]=nil;tick(.5)
check(#get('SessionScoreboard','Players'):GetChildren()==2,'departed player row is released')
focus:Fire();check(not get('SessionScoreboard').Visible,'window focus loss cannot leave scoreboard stuck')
player:SetAttribute('ZO_ShopOpen',true);actions.ZO_Scoreboard(nil,'Begin');tick()
check(not get('SessionScoreboard').Visible and not get('Vitals').Visible,'shop takes precedence over scoreboard and lower HUD')
player:SetAttribute('ZO_ShopOpen',false)
local folder=object('Folder','ZO_Barricades',world);local prop=object('Model','Crate',folder)
prop:SetAttribute('ZO_Health',90);prop:SetAttribute('ZO_MaxHealth',180);prop:SetAttribute('ZO_Label','Caixa')
local hull=object('Part','Hull',prop);rayHit={Instance=hull,Position=root.Position};tick()
check(get('Barricade').Visible and get('Barricade','Resistance','Fill').Size.X.Scale==.5,'nearby prop shows current server durability')
prop:SetAttribute('ZO_Destroyed',true);tick();check(not get('Barricade').Visible,'destroyed prop loses inspection prompt')
camera.ViewportSize={X=640,Y=480};uis.TouchEnabled=true;tick()
check(get('RoundHeader').Size.X.Offset<=616 and get('ScoreboardToggle').Text=='PLACAR','small touch viewport adapts header and scoreboard control')
player.CharacterRemoving:Fire(char);player.Character=nil;tick();check(not get('Vitals').Visible,'respawn gap clears old character vitals')
char,hum,root=spawn()
local map=object('Model','ZO_K17Foundry',world);local controls=object('Model','EscapeObjectives',map)
local control=object('Part','Control1',controls);control.Position=vec(150,4,-224)
local bay=object('Model','R50_EvacuationBay',map);local gate=object('Part','EvacuationGate',bay);gate.Position=vec(228,6,242)
rs:SetAttribute('ZO_RoundMode','Escape');rs:SetAttribute('ZO_RoundState','Active');rs:SetAttribute('ZO_EscapeStatus','Ready')
rs:SetAttribute('ZO_EscapeStage',1);rs:SetAttribute('ZO_EscapeLabel','Gerador');tick()
check(get('EscapeWaypoint').Enabled and get('EscapeWaypoint').Adornee==control,'Escape guidance targets the current static controller')
local escapeData
for _,value in moduleMap do if type(value)=='table' and value.Stages then escapeData=value end end
escapeData.Paths={{{-68,1,-136},{-68,1,-124},{144,1,-224}}}
tick()
local guide=get('EscapeWaypoint').Adornee
check(guide.Name=='ZO_EscapeGuidePoint' and guide.Position.Z==-124 and not guide.CanQuery and not guide.CanCollide,'route guidance selects the next access without adding a collision or ray target')
root.Position=control.Position;tick()
check(get('EscapeWaypoint').Adornee==control,'near the objective guidance returns to the real interactable')
check(get('Objective').Text:find('1/3',1,true)~=nil,'Escape objective sequence is shown in HUD')
rs:SetAttribute('ZO_EscapeStatus','Holding');rs:SetAttribute('ZO_EscapeRemaining',12);tick()
check(get('RoundHeader','Clock').Text=='00:12','defense clock uses objective deadline')
rs:SetAttribute('ZO_HoldGateStatus','Closed');tick()
check(get('Controls').Text:find('retenção',1,true)~=nil,'closed retention explains the defense to the player')
rs:SetAttribute('ZO_EscapeStatus','Extraction');rs:SetAttribute('ZO_EscapeStage',3);tick()
check(get('EscapeWaypoint').Adornee==gate,'extraction guidance moves from panel to terminal entrance')
rs:SetAttribute('ZO_RoundState','Results');rs:SetAttribute('ZO_LastWinner','Humans');rs:SetAttribute('ZO_LastEscaped',1);tick()
check(get('Objective').Text:find('1 humanos',1,true)~=nil and not get('EscapeWaypoint').Enabled,'Escape results preserve rescued count and clear active guidance')
rs:SetAttribute('ZO_RoundId',1);rs:SetAttribute('ZO_SummaryRound',1);rs:SetAttribute('ZO_MVPName','Player')
for key,value in {Round=1,Shots=3,Hits=2,Damage=45,Kills=1,Headshots=1,Infections=0,Objectives=3,Reward=800,Credits=5000}do player:SetAttribute('ZO_Summary'..key,value)end
player:SetAttribute('ZO_EscapedRound',1);tick()
check(get('RoundSummary').Visible and get('RoundSummary','Statistics').Text:find('PRECISÃO 67%',1,true)~=nil,'results project confirmed shot accuracy and extraction status')
check(get('RoundSummary','Credits').Text:find('$800',1,true)~=nil and get('RoundSummary','Highlight').Text:find('Player',1,true)~=nil,'result shows actual reward and server highlight')
get('RoundSummary','Close').Activated:Fire();tick();check(not get('RoundSummary').Visible,'closing summary remains dismissed for this result')
rs:SetAttribute('ZO_RoundId',2);rs:SetAttribute('ZO_SummaryRound',2);player:SetAttribute('ZO_ResultRound',2);tick()
check(get('RoundSummary').Visible and get('RoundSummary','Statistics').Text=='Preparando seu resumo…','new result never reuses stale personal statistics')
player:SetAttribute('ZO_ResultRound',0);tick()
check(get('RoundSummary','Statistics').Text:find('espectador',1,true)~=nil,'late spectator receives no fabricated combat statistics')
gui:Destroy();tick()
check(player:GetAttribute('ZO_TacticalHUDReady')==false and actions.ZO_Scoreboard==nil,'teardown restores fallback and releases input binding')
print(('PASS actual tactical HUD: %d checks; state/cleanup API doubles, no rendering simulation'):format(checks))
