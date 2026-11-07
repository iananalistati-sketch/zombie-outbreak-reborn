-- Camera/Instance doubles execute the real local script; no light rendering.
local checks=0
local function check(v,label)assert(v,label);checks+=1 end
local function signal()
    local callbacks={}
    return {Connect=function(_,fn)table.insert(callbacks,fn);return{Disconnect=function()end}end,
        Fire=function(_,...)for _,fn in table.clone(callbacks)do fn(...)end end}
end
local methods={}
local function object(class,name,parent)
    local data={ClassName=class,Name=name or class,attrs={},children={}}
    local o=setmetatable({data=data},{__index=function(_,k)return methods[k]or data[k]end,
        __newindex=function(self,k,v)
            if k=='Parent'then
                assert(not data.destroyed,'cannot reparent destroyed Instance')
                if data.Parent then data.Parent.data.children[self]=nil end
                data.Parent=v;if v then v.data.children[self]=true end
            else data[k]=v end
        end})
    o.Destroying=signal();if parent then o.Parent=parent end;return o
end
function methods:GetAttribute(k)return self.data.attrs[k]end
function methods:SetAttribute(k,v)self.data.attrs[k]=v end
function methods:GetChildren()local a={};for child in self.data.children do table.insert(a,child)end;return a end
function methods:FindFirstChild(name)for _,v in self:GetChildren()do if v.Name==name then return v end end end
function methods:FindFirstChildOfClass(class)for _,v in self:GetChildren()do if v.ClassName==class then return v end end end
function methods:Destroy()
    if self.data.destroyed then return end
    self.Destroying:Fire();for _,v in self:GetChildren()do v:Destroy()end;self.Parent=nil;self.data.destroyed=true
end
local cfmeta={__mul=function(a,b)return setmetatable({X=a.X+b.X,Y=a.Y+b.Y,Z=a.Z+b.Z},getmetatable(a))end}
local function cf(x,y,z)return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},cfmeta)end
local player=object('Player','Player');player.Team={Name='Humans'}
local char=object('Model','Character');player.Character=char
local hum=object('Humanoid','Humanoid',char);hum.Health=100
local rs=object('ReplicatedStorage','ReplicatedStorage');rs:SetAttribute('ZO_RoundState','Training')
local world={CurrentCamera=object('Camera','Camera')};world.CurrentCamera.CFrame=cf(0,5,0)
local scriptObject=object('LocalScript','Flashlight')
local actions,bindings={},{}
local button={Visible=false}
local cas={BindActionAtPriority=function(_,n,f,_,_,...)actions[n]={f=f,keys={...}}end,
    SetTitle=function()end,SetPosition=function()end,GetButton=function()return button end,
    UnbindAction=function(_,n)actions[n]=nil end}
local run={BindToRenderStep=function(_,n,_,f)bindings[n]=f end,UnbindFromRenderStep=function(_,n)bindings[n]=nil end}
local focus=false;local gui={MenuIsOpen=false}
local services={Players={LocalPlayer=player},ReplicatedStorage=rs,RunService=run,ContextActionService=cas,
    UserInputService={GetFocusedTextBox=function()return if focus then {}else nil end},GuiService=gui}
local enum=setmetatable({RenderPriority={Camera={Value=100}}},{__index=function()return setmetatable({},{__index=function(_,k)return k end})end})
local env=setmetatable({game={GetService=function(_,n)return services[n]end},workspace=world,script=scriptObject,
    Instance={new=function(c)return object(c)end},Enum=enum,CFrame={new=cf},Vector3={new=function(...)return{...}end},
    Color3={fromRGB=function(...)return{...}end},UDim2={new=function(...)return{...}end}},{__index=getfenv()})
local fn=assert(loadstring(SOURCE));setfenv(fn,env);fn()
local function tick()for _,f in bindings do f()end end
local function toggle()return actions.ZO_Flashlight.f(nil,'Begin')end
tick()
local mount=world.CurrentCamera:FindFirstChild('ZO_FlashlightMount');local beam=mount:FindFirstChild('Beam')
check(beam.Enabled and beam.Range==48 and beam.Shadows,'default local beam uses bounded range and shadows')
check(not mount.CanQuery and not mount.CanCollide and mount.Anchored,'light cannot block aim or alter physics')
check(math.abs(mount.CFrame.Y-4.85)<1e-5,'mount follows actual camera transform')
check(actions.ZO_Flashlight.keys[1]=='F'and actions.ZO_Flashlight.keys[2]=='DPadRight','input avoids weapon slot and scoreboard gamepad bindings')
toggle();tick();check(not beam.Enabled and not player:GetAttribute('ZO_FlashlightOn'),'F disables beam')
focus=true;check(toggle()=='Pass','typing does not toggle flashlight');focus=false;tick();check(not beam.Enabled,'typing preserved preference')
toggle();tick();player:SetAttribute('ZO_ShopOpen',true);tick();check(not beam.Enabled and not button.Visible,'arsenal suspends beam and touch action')
player:SetAttribute('ZO_ShopOpen',nil);tick();check(beam.Enabled,'closing modal restores prior preference')
local oldCamera=world.CurrentCamera;world.CurrentCamera=object('Camera','Replacement');world.CurrentCamera.CFrame=cf(4,8,0);tick()
check(mount.Parent==world.CurrentCamera and #oldCamera:GetChildren()==0,'camera replacement moves single mount without duplication')
world.CurrentCamera=nil;tick();check(not beam.Enabled,'missing camera safely disables beam')
world.CurrentCamera=mount.Parent;player:SetAttribute('ZO_Spectating',true);tick();check(not beam.Enabled,'spectating cannot reveal terrain with own beam')
player:SetAttribute('ZO_Spectating',nil);player:SetAttribute('ZO_SpawnPending',true);tick();check(not beam.Enabled,'pending return does not emit beam from lobby')
player:SetAttribute('ZO_SpawnPending',nil);hum.Health=0;tick();check(not beam.Enabled,'death disables beam')
hum.Health=100;rs:SetAttribute('ZO_RoundState','Results');tick();check(not beam.Enabled,'results disable beam')
rs:SetAttribute('ZO_RoundState','Active');tick();check(beam.Enabled,'new active round restores preference')
mount:Destroy();tick();local replacement=world.CurrentCamera:FindFirstChild('ZO_FlashlightMount')
check(replacement~=mount and #world.CurrentCamera:GetChildren()==1,'destroyed camera mount is recreated once')
player:SetAttribute('ZO_ShopOpen',true);replacement:Destroy();tick()
check(#world.CurrentCamera:GetChildren()==0,'destroyed mount during a modal is not illegally reparented')
player:SetAttribute('ZO_ShopOpen',nil);tick()
check(#world.CurrentCamera:GetChildren()==1,'closing modal can recreate missing mount safely')
scriptObject:Destroy();tick()
check(#world.CurrentCamera:GetChildren()==0 and not actions.ZO_Flashlight and not bindings.ZO_FlashlightCamera,'teardown removes owned light and input/render callbacks')
print(('PASS actual local flashlight lifecycle: %d checks; camera/Instance doubles, no rendering'):format(checks))
