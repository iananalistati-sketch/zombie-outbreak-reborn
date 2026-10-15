-- Sources are injected by run_runtime.py. This executes the current real Script.
-- Doubles verify API/control-flow contracts; no Roblox contacts or replication run.
local Config=assert(loadstring(CONFIG_SOURCE))()
local Rules=assert(loadstring(RULES_SOURCE))()
local Physics=assert(loadstring(PHYSICS_SOURCE))()
local checks=0
local function check(ok,label) assert(ok,label);checks+=1 end
local expected=0
local names={}
for name in Config.Props do expected+=1;table.insert(names,name) end
table.sort(names)
local Vector={}
local vmt={__type="Vector3"}
local vectorAllocations=0
function Vector.new(x,y,z) vectorAllocations+=1;return setmetatable({X=x,Y=y,Z=z},vmt) end
Vector.zero=Vector.new(0,0,0)
vmt.__add=function(a,b) return Vector.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vmt.__sub=function(a,b) return Vector.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
vmt.__mul=function(a,b) return Vector.new(a.X*b,a.Y*b,a.Z*b) end
vmt.__div=function(a,b) return Vector.new(a.X/b,a.Y/b,a.Z/b) end
vmt.__index=function(v,k)
    if k=="Magnitude" then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end
    if k=="Unit" then return v/v.Magnitude end
end
local function signal()
    local handlers={}
    return {Connect=function(_,fn) table.insert(handlers,fn);return {Disconnect=function() end} end,
        Fire=function(_,...) for _,fn in handlers do fn(...) end end}
end
local function simulation(options)
    options=options or {}
    local catalog=options.catalog or Config
    local now=0
    local deferred={}
    local warnings={}
    local methods={}
    local function instance(class,name)
        local data={ClassName=class,Name=name or class,_attrs={},_children={},_signals={}}
        local value={_data=data}
        setmetatable(value,{__index=function(_,key) return methods[key] or data[key] or data._children[key] end,
            __newindex=function(_,key,new)
                if key=="Parent" then
                    if data.Parent then data.Parent._children[data.Name]=nil end
                    data.Parent=new
                    if new then new._children[data.Name]=value end
                else data[key]=new end
            end})
        return value
    end
    function methods:IsA(kind) return self.ClassName==kind or kind=="Instance" or (self.ClassName=="Part" and kind=="BasePart") end
    function methods:GetAttribute(key) return self._attrs[key] end
    function methods:SetAttribute(key,v) local changed=self._attrs[key]~=v;self._attrs[key]=v;if changed and self._signals[key] then self._signals[key]:Fire() end end
    function methods:GetAttributeChangedSignal(key) self._signals[key]=self._signals[key] or signal();return self._signals[key] end
    function methods:GetChildren() local list={};for _,v in self._children do table.insert(list,v) end;return list end
    function methods:GetDescendants() local list={};local function collect(parent) for _,v in parent:GetChildren() do table.insert(list,v);collect(v) end end;collect(self);return list end
    function methods:FindFirstChild(key) return self._children[key] end
    function methods:FindFirstChildOfClass(kind) for _,v in self._children do if v:IsA(kind) then return v end end;return nil end
    function methods:WaitForChild(key) return assert(self:FindFirstChild(key),"Unexpected yield: "..self.Name.."."..key) end
    function methods:IsDescendantOf(ancestor) local p=self.Parent;while p do if p==ancestor then return true end;p=p.Parent end;return false end
    function methods:FindFirstAncestorOfClass(kind) local p=self.Parent;while p do if p:IsA(kind) then return p end;p=p.Parent end;return nil end
    function methods:Destroy() self.Parent=nil end
    function methods:Clone()
        local clone=instance(self.ClassName,self.Name)
        for key,v in self._data do if key~="Parent" and string.sub(key,1,1)~="_" then clone[key]=v end end
        clone._data._attrs=table.clone(self._attrs)
        for _,child in self:GetChildren() do local copy=child:Clone();copy.Parent=clone end
        return clone
    end
    local rs=instance("ReplicatedStorage","ReplicatedStorage")
    local ss=instance("ServerStorage","ServerStorage")
    local world=instance("Workspace","Workspace")
    local folder=instance("Folder","ZO_Barricades");folder.Parent=world
    local internal=instance("Folder","ZO_Gameplay");internal.Parent=ss
    local damage=instance("BindableFunction","DamageBarricade");damage.Parent=internal
    local push=instance("BindableFunction","PushBarricade");push.Parent=internal
    local activated=0
    function methods:CanSetNetworkOwnership()
        check(type(damage.OnInvoke)=="function" and type(push.OnInvoke)=="function","callbacks installed before physical activation")
        check(not self.Anchored,"unanchor hull before ownership")
        for _,part in self.Parent:GetChildren() do
            if part:IsA("BasePart") and part~=self then
                check(not part.Anchored and part.Massless and not part.CanCollide,"visual part is unanchored, massless and noncolliding")
                local welded=false
                for _,weld in self:GetChildren() do if weld:IsA("WeldConstraint") and weld.Part0==self and weld.Part1==part then welded=true end end
                check(welded,"visual part welded before unanchoring hull")
            end
        end
        return true,nil
    end
    function methods:SetNetworkOwner(owner)
        assert(owner==nil,"server must own physical assemblies")
        if self.Parent.Name==options.failName and options.failOwnership then error("injected SetNetworkOwner failure") end
        activated+=1;self.ServerOwned=true
    end
    function methods:ApplyImpulse(impulse) self.AssemblyLinearVelocity=self.AssemblyLinearVelocity+impulse/self.AssemblyMass end
    for name,prop in catalog.Props do
        if name==options.missingName then continue end
        local kind=catalog.Kinds[prop.Kind]
        local model=instance("Model",name);model.Parent=folder
        local hull=instance("Part","Hull");hull.Parent=model
        hull.Size=Vector.new(kind.Width,kind.Height,kind.Depth)
        hull.Position=Vector.new(prop.X,prop.Y+kind.Height/2,prop.Z)
        hull.Anchored=true;hull.CanCollide=true;hull.AssemblyMass=kind.Mass
        hull.AssemblyLinearVelocity=Vector.zero;hull.AssemblyAngularVelocity=Vector.zero
        local skin=instance("Part","Skin");skin.Parent=model;skin.Anchored=true;skin.CanCollide=false
    end
    local players=instance("Players","Players");players.PlayerAdded=signal();players.PlayerRemoving=signal()
    local list={}
    function players:GetPlayers() return list end
    local shared=instance("Folder","K17Barricades");shared.Parent=rs
    local modules={}
    for name,result in {Config=catalog,Rules=Rules,Physics=Physics,Placement={closest=function(hull) return hull.Position end}} do
        local m=instance("ModuleScript",name);m.Parent=shared;modules[m]=result
    end
    local heartbeat=signal()
    local services={Players=players,ReplicatedStorage=rs,ServerStorage=ss,RunService={Heartbeat=heartbeat,IsStudio=function() return true end}}
    local env=setmetatable({game={GetService=function(_,name) return assert(services[name],name) end},workspace=world,Vector3=Vector,
        Instance={new=function(class) return instance(class) end},Enum={ModelStreamingMode={Atomic="Atomic"},RaycastFilterType={Exclude="Exclude"}},
        PhysicalProperties={new=function(density,friction,elasticity,fw,ew) assert(density>=.01 and density<=100,"valid density");return {density,friction,elasticity,fw,ew} end},
        RaycastParams={new=function() return {} end},task={defer=function(fn) table.insert(deferred,fn) end},
        require=function(m) return assert(modules[m],m.Name) end,
        typeof=function(v) local mt=if type(v)=="table" then getmetatable(v) else nil;return if mt==vmt then "Vector3" elseif type(v)=="table" and v.ClassName then "Instance" else type(v) end,
        os={clock=function() return now end},
        warn=function(message) table.insert(warnings,message) end,print=function() end}, {__index=getfenv()})
    rs:SetAttribute("ZO_RoundState","Preparation")
    local fn=assert(loadstring(SERVER_SOURCE,"Barricades.server.luau"));setfenv(fn,env)
    local ok,message=pcall(fn)
    check(ok,"real barricade controller must complete startup: "..tostring(message))
    local function flush() while #deferred>0 do table.remove(deferred,1)() end end
    return {rs=rs,folder=folder,internal=internal,warnings=warnings,heartbeat=heartbeat,options=options,flush=flush,
        advance=function(seconds) now+=seconds end,world=world,
        remove=function(player)
            local index=table.find(list,player);if index then table.remove(list,index) end
            players.PlayerRemoving:Fire(player)
        end,
        actor=function(role)
            local p=instance("Player","TestPlayer");p.Team={Name=role}
            local char=instance("Model","Character");p.Character=char
            local head=instance("Part","Head");head.Parent=char;head.Position=Vector.new(0,2,0)
            local hum=instance("Humanoid","Humanoid");hum.Parent=char;hum.Health=100
            table.insert(list,p);players.PlayerAdded:Fire(p);return p
        end}
end

do
    local s=simulation()
    check(s.rs:GetAttribute("ZO_BarricadesReady")==true,"all valid props produce Ready")
    check(s.rs:GetAttribute("ZO_BarricadesActive")==expected and s.rs:GetAttribute("ZO_BarricadesExpected")==expected,"dynamic catalogue counts")
    check(s.rs:GetAttribute("ZO_BarricadesErrors")==0,"no startup failures")
    local model=s.folder:FindFirstChild(names[1]);local hull=model:FindFirstChild("Hull")
    local human=s.actor("Humans")
    check(s.internal.PushBarricade.OnInvoke(human,hull,Vector.new(1,0,0)),"server rifle callback pushes a valid prop")
    check(hull.AssemblyLinearVelocity.X>0 and hull.AssemblyLinearVelocity.X<=Config.Physics.MaxSpeed,"bounded physical impulse")
    check(not s.internal.PushBarricade.OnInvoke(human,hull,Vector.new(0/0,0,0)),"reject nonfinite shot direction")
    model:SetAttribute("ZO_Health",1)
    s.rs:SetAttribute("ZO_RoundState","Active");s.rs:SetAttribute("ZO_RoundState","Preparation");s.flush()
    local restored=s.folder:FindFirstChild(names[1])
    check(restored~=model and restored:GetAttribute("ZO_Health")==Config.Kinds[Config.Props[names[1]].Kind].Health,"preparation restores original template and health")
    check(restored.Hull.ServerOwned and restored.Hull.AssemblyLinearVelocity.Magnitude==0,"reset assembly is server-owned at rest")
    restored.Hull.Position=Vector.new(400,0,0);s.heartbeat:Fire(.1)
    check(s.folder:FindFirstChild(names[1])~=restored,"out-of-world prop restored independently")
    check(s.rs:GetAttribute("ZO_BarricadesReady"),"lost-prop recovery restores Ready")
    s.folder:FindFirstChild(names[1]):Destroy();s.heartbeat:Fire(.1)
    check(s.rs:GetAttribute("ZO_BarricadesActive")==expected and s.rs:GetAttribute("ZO_BarricadesReady"),"removed model recovery does not keep an orphaned entry")
    local target=s.folder:FindFirstChild(names[1]);local zombie=s.actor("Zombies")
    s.rs:SetAttribute("ZO_RoundState","Active")
    zombie.Character.Head.Position=target.Hull.Position-Vector.new(2,0,0)
    s.world.Raycast=function() return {Instance=target.Hull} end
    local remaining=target:GetAttribute("ZO_MaxHealth")
    while remaining>0 do
        local health=s.internal.DamageBarricade.OnInvoke(zombie,target.Hull)
        remaining=math.max(0,remaining-Config.MeleeDamage)
        check(health==remaining,"zombie melee keeps authoritative prop health")
        check(s.internal.DamageBarricade.OnInvoke(zombie,target.Hull)==nil,"melee cooldown rejects repeated event")
        s.advance(Config.MeleeCooldown+.01)
    end
    check(target:GetAttribute("ZO_Destroyed") and target.Hull.Anchored and not target.Hull.CanCollide and not target.Hull.CanQuery,"destroyed prop stops collision and physics")
    s.rs:SetAttribute("ZO_RoundState","Preparation");s.flush()
    check(not s.folder:FindFirstChild(names[1]):GetAttribute("ZO_Destroyed"),"next round restores destroyed prop")
end

do
    local s=simulation({failName=names[1],failOwnership=true})
    check(not s.rs:GetAttribute("ZO_BarricadesReady") and s.rs:GetAttribute("ZO_BarricadesAvailable"),"one engine/API error degrades props without aborting controller")
    check(s.rs:GetAttribute("ZO_BarricadesActive")==expected-1 and s.rs:GetAttribute("ZO_BarricadesErrors")==1,"failed assembly excluded from active count")
    check(#s.warnings==1 and string.find(s.rs:GetAttribute("ZO_BarricadesLastError"),names[1],1,true)~=nil,"failed prop has persistent named diagnostic")
    check(s.folder:FindFirstChild(names[1]).Hull.Anchored,"failed assembly quarantined anchored")
    check(not s.internal.PushBarricade.OnInvoke(s.actor("Humans"),s.folder:FindFirstChild(names[1]).Hull,Vector.new(1,0,0)),"failed prop callbacks reject safely")
    s.options.failOwnership=false;s.rs:SetAttribute("ZO_RoundState","Active");s.rs:SetAttribute("ZO_RoundState","Preparation");s.flush()
    check(s.rs:GetAttribute("ZO_BarricadesReady") and s.rs:GetAttribute("ZO_BarricadesErrors")==0,"next preparation retries and recovers failed assembly")
end

do
    local s=simulation({missingName=names[1]})
    check(s.rs:GetAttribute("ZO_BarricadesStatus")=="Degraded" and s.rs:GetAttribute("ZO_BarricadesActive")==expected-1,"missing authored model is reported without infinite yield")
    check(type(s.internal.DamageBarricade.OnInvoke)=="function" and type(s.internal.PushBarricade.OnInvoke)=="function","private callbacks remain callable after missing model")
end

do
    local catalog=table.clone(Config);catalog.Props={}
    local kinds={"Cabinet","Crate","Table"}
    for index=1,180 do
        catalog.Props[string.format("Stress%03d",index)]={Kind=kinds[(index-1)%#kinds+1],X=((index-1)%30)*8-120,Y=1,Z=math.floor((index-1)/30)*8-24,Refuge=7}
    end
    local s=simulation({catalog=catalog})
    check(s.rs:GetAttribute("ZO_BarricadesReady") and s.rs:GetAttribute("ZO_BarricadesActive")==180,"180-prop catalogue initializes without fixed count assumptions")
    check(s.rs:GetAttribute("ZO_BarricadesMaintenanceHz")==1,"empty server uses one safety pass per second")
    local allocations=vectorAllocations
    s.heartbeat:Fire(1)
    check(vectorAllocations==allocations,"stationary safety pass allocates no temporary vectors across 180 props")
    local human=s.actor("Humans")
    check(s.rs:GetAttribute("ZO_BarricadesMaintenanceHz")==10,"joining player restores ten safety passes per second")
    allocations=vectorAllocations
    for _=1,100 do s.heartbeat:Fire(.1) end
    check(vectorAllocations==allocations,"100 populated safety passes preserve allocation-free stationary path")
    local hull=s.folder:FindFirstChild("Stress001").Hull
    hull.AssemblyLinearVelocity=Vector.new(25,20,0);hull.AssemblyAngularVelocity=Vector.new(0,15,0)
    s.heartbeat:Fire(.1)
    check(hull.AssemblyLinearVelocity.X<=catalog.Physics.MaxSpeed and hull.AssemblyLinearVelocity.Y==8,"safety pass still caps excessive horizontal and upward velocity")
    check(hull.AssemblyAngularVelocity.Magnitude<=catalog.Physics.MaxSpin+.000001,"safety pass still caps excessive angular velocity")
    for _,model in s.folder:GetChildren() do check(not model.Hull.Anchored,"distant valid props remain physical instead of frozen by distance") end
    s.remove(human)
    check(s.rs:GetAttribute("ZO_BarricadesMaintenanceHz")==1,"last disconnect restores empty-server cadence")
    local old=s.folder:FindFirstChild("Stress002");old.Hull.Position=Vector.new(400,0,0)
    s.heartbeat:Fire(.5)
    check(s.folder:FindFirstChild("Stress002")==old,"empty-server pass is not run on every frame")
    s.heartbeat:Fire(.5)
    check(s.folder:FindFirstChild("Stress002")~=old and s.rs:GetAttribute("ZO_BarricadesReady"),"empty server still recovers lost props at one-second cadence")
end
print(("PASS actual barricade controller: %d assertions; startup, isolation, resets, 180-prop safety passes and callbacks; engine physics not executed"):format(checks))
