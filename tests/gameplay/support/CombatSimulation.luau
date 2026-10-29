-- Shared deterministic Roblox API doubles, extracted from the existing Combat suite.
-- These do not implement rendering, physics, asset loading or real networking.
return function(deps)
local Config,Rules,WeaponState=deps.Config,deps.Rules,deps.WeaponState
local LoadoutState,Containment=deps.LoadoutState,deps.Containment
local COMBAT_SOURCE=deps.CombatSource
-- Engine float properties do not preserve every Luau double. Model that storage
-- boundary so equality-based effect ownership cannot pass on table precision.
local floatStorage=buffer.create(4)
local function propertyFloat(value)
    buffer.writef32(floatStorage,0,value)
    return buffer.readf32(floatStorage,0)
end
local Vector={}
local vmt={}
function Vector.new(x,y,z) return setmetatable({X=x,Y=y,Z=z},vmt) end
Vector.zero=Vector.new(0,0,0);Vector.one=Vector.new(1,1,1)
Vector.xAxis=Vector.new(1,0,0);Vector.yAxis=Vector.new(0,1,0);Vector.zAxis=Vector.new(0,0,1)
vmt.__add=function(a,b) return Vector.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vmt.__sub=function(a,b) return Vector.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
vmt.__unm=function(a) return Vector.new(-a.X,-a.Y,-a.Z) end
vmt.__mul=function(a,b) if type(a)=="number" then a,b=b,a end;return Vector.new(a.X*b,a.Y*b,a.Z*b) end
vmt.__div=function(a,b) return Vector.new(a.X/b,a.Y/b,a.Z/b) end
vmt.__index=function(v,key)
    if key=="Magnitude" then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end
    if key=="Unit" then return v/v.Magnitude end
    if key=="Dot" then return function(a,b) return a.X*b.X+a.Y*b.Y+a.Z*b.Z end end
    if key=="Cross" then return function(a,b) return Vector.new(a.Y*b.Z-a.Z*b.Y,a.Z*b.X-a.X*b.Z,a.X*b.Y-a.Y*b.X) end end
    if key=="Lerp" then return function(a,b,alpha) return a+(b-a)*alpha end end
end
local function basis(position,look)
    local forward=(look-position).Unit
    local right=forward:Cross(Vector.yAxis)
    if right.Magnitude<.001 then right=Vector.xAxis else right=right.Unit end
    local up=right:Cross(forward).Unit
    return setmetatable({Position=position,LookVector=forward,RightVector=right,UpVector=up,
        VectorToWorldSpace=function(_,v) return right*v.X+up*v.Y-forward*v.Z end},
        {__mul=function(a,b) local p=a.Position+b.Position;return basis(p,p+a.LookVector) end})
end

local function simulation(options)
    options=options or {}
    local now=10
    local queue={}
    local errors={}
    local function schedule(thread,at,args) table.insert(queue,{thread=thread,at=at,args=args or {}}) end
    local tasks={}
    function tasks.spawn(fn,...) local thread=if type(fn)=="thread" then fn else coroutine.create(fn);schedule(thread,now,{...});return thread end
    tasks.defer=tasks.spawn
    function tasks.delay(delay,fn,...) schedule(coroutine.create(fn),now+delay,{...}) end
    function tasks.wait(delay) return coroutine.yield(delay or .03) end
    function tasks.cancel(thread) for index=#queue,1,-1 do if queue[index].thread==thread then table.remove(queue,index) end end end
    local function signal()
        local handlers={}
        return {
            Connect=function(_,fn) table.insert(handlers,fn);return {Disconnect=function() local i=table.find(handlers,fn);if i then table.remove(handlers,i) end end} end,
            Fire=function(_,...) for _,fn in table.clone(handlers) do tasks.spawn(fn,...) end end,
        }
    end
    local methods={}
    local instance
    instance=function(class,name,parent)
        local data={ClassName=class,Name=name or class,_children={},_attrs={},_attributes={},_properties={},_calls={}}
        local value={_data=data}
        setmetatable(value,{__index=function(_,key) return methods[key] or data[key] or data._children[key] end,
            __newindex=function(_,key,new)
                if class=="Humanoid" and key=="WalkSpeed" then new=propertyFloat(new) end
                local previous=data[key]
                if key=="Parent" then
                    if previous then previous._children[data.Name]=nil;previous.ChildRemoved:Fire(value) end
                    data.Parent=new
                    if new then new._children[data.Name]=value;new.ChildAdded:Fire(value) end
                    value.AncestryChanged:Fire(value,new)
                else data[key]=new end
                if previous~=new and data._properties[key] then data._properties[key]:Fire() end
            end})
        value.ChildAdded=signal();value.ChildRemoved=signal();value.AncestryChanged=signal()
        if class=="RemoteEvent" then value.OnServerEvent=signal() end
        if class=="Humanoid" then value.Died=signal();value.Health=100;value.WalkSpeed=18;value.FloorMaterial="Concrete";value.MoveDirection=Vector.zero end
        if class=="Part" then
            value.Position=Vector.zero;value.CFrame=basis(Vector.zero,-Vector.zAxis)
            value.Anchored=false;value.AssemblyMass=12;value.AssemblyLinearVelocity=Vector.zero;value.Color={.5,.5,.5}
        end
        if parent then value.Parent=parent end
        return value
    end
    function methods:IsA(kind) return self.ClassName==kind or kind=="Instance" or (self.ClassName=="Part" and kind=="BasePart") end
    function methods:GetChildren() local result={};for _,child in self._children do table.insert(result,child) end;return result end
    function methods:GetDescendants() local result={};local function add(parent) for _,child in parent:GetChildren() do table.insert(result,child);add(child) end end;add(self);return result end
    function methods:FindFirstChild(name) return self._children[name] end
    function methods:WaitForChild(name) return assert(self._children[name],"Unexpected dependency/yield: "..self.Name.."."..name) end
    function methods:FindFirstChildOfClass(class) for _,child in self._children do if child:IsA(class) then return child end end;return nil end
    function methods:FindFirstAncestorOfClass(class) local node=self.Parent;while node do if node:IsA(class) then return node end;node=node.Parent end;return nil end
    function methods:IsDescendantOf(ancestor) local node=self.Parent;while node do if node==ancestor then return true end;node=node.Parent end;return false end
    function methods:GetAttribute(key) return self._attrs[key] end
    function methods:SetAttribute(key,value) local changed=self._attrs[key]~=value;self._attrs[key]=value;if changed and self._attributes[key] then self._attributes[key]:Fire() end end
    function methods:GetAttributeChangedSignal(key) self._attributes[key]=self._attributes[key] or signal();return self._attributes[key] end
    function methods:GetPropertyChangedSignal(key) self._properties[key]=self._properties[key] or signal();return self._properties[key] end
    function methods:Destroy() self.Parent=nil end
    function methods:Invoke(...) table.insert(self._calls,{...});return if self.OnInvoke then self.OnInvoke(...) else nil end
    function methods:FireClient(player,...) table.insert(self._calls,{player,...}) end
    function methods:FireAllClients(...) table.insert(self._calls,{...}) end
    function methods:TakeDamage(damage)
        table.insert(self._calls,{damage});local wasAlive=self.Health>0;self.Health=math.max(0,self.Health-damage)
        if wasAlive and self.Health<=0 then self.Died:Fire() end
    end
    function methods:ApplyImpulse(impulse) table.insert(self._calls,{impulse});self.AssemblyLinearVelocity+=impulse/self.AssemblyMass end
    function methods:PivotTo(cf) self.Pivot=cf;self.PivotCount=(self.PivotCount or 0)+1 end
    local players=instance("Players","Players");players.PlayerAdded=signal();players.PlayerRemoving=signal()
    local list={}
    function players:GetPlayers() return table.clone(list) end
    function players:GetPlayerFromCharacter(char) for _,player in list do if player.Character==char then return player end end;return nil end
    local rs=instance("ReplicatedStorage","ReplicatedStorage")
    local ss=instance("ServerStorage","ServerStorage")
    local world=instance("Workspace","Workspace")
    function world:GetServerTimeNow() return now+1000 end
    local raycasts={}
    local raycast
    function world:Raycast(origin,direction,params)
        table.insert(raycasts,{origin=origin,direction=direction,params=params})
        return if raycast then raycast(origin,direction,params,#raycasts) else nil
    end
    local internal=instance("Folder","ZO_Gameplay",ss)
    local infect=instance("BindableFunction","Infect",internal);infect.OnInvoke=function() return false end
    local damage=instance("BindableFunction","DamageBarricade",internal);damage.OnInvoke=function() return 100 end
    local push=instance("BindableFunction","PushBarricade",internal);push.OnInvoke=function() return true end
    local props=instance("Folder","ZO_Barricades",world)
    local shared=instance("Folder","K17Gameplay",rs)
    local weaponAssets=instance("Folder","ZO_WeaponAssets",rs)
    local templates=instance("Folder","Weapons",weaponAssets)
    for _,id in Config.WeaponOrder do instance("Tool",id,templates) end
    local modules={}
    for name,result in {Config=Config,Rules=Rules,WeaponState=WeaponState,LoadoutState=LoadoutState,Containment=Containment} do
        local module=instance("ModuleScript",name,shared);modules[module]=result
    end
    local heartbeat=signal()
    local services={Players=players,ReplicatedStorage=rs,ServerStorage=ss,Workspace=world,
        RunService={Heartbeat=heartbeat,IsStudio=function() return false end}}
    if options.roundSource then
        services.Teams=instance("Teams","Teams")
        services.ScriptContext={Error=signal()}
        local roundShared=instance("Folder","Shared",rs)
        for name,result in {RoundConfig=options.roundConfig,MapConfig=options.mapConfig} do
            local module=instance("ModuleScript",name,roundShared);modules[module]=result
        end
        local rules=instance("ModuleScript","RoundRules",shared);modules[rules]=options.roundRules
        local map=instance("Model",options.mapConfig.ModelName,world)
        local spawns=instance("Model","Spawns",map)
        for _,name in {options.mapConfig.HumanSpawn,options.mapConfig.ZombieSpawn,options.mapConfig.LobbySpawn} do
            instance("Part",name,spawns)
        end
    end
    local env=setmetatable({game={GetService=function(_,name) return assert(services[name],name) end},workspace=world,
        Vector3=Vector,CFrame={lookAt=basis,new=function(x,y,z) return basis(Vector.new(x or 0,y or 0,z or 0),Vector.new(x or 0,y or 0,(z or 0)-1)) end},
        Enum={RaycastFilterType={Exclude="Exclude"},Material={Air="Air"}},RaycastParams={new=function() return {} end},
        Random={new=function() return {NextNumber=function(_,low,high) return ((low or 0)+(high or 1))/2 end,
            NextInteger=function(_,low) return low end} end},
        BrickColor={new=function(name) return name end},Color3={fromRGB=function(...) return {...} end},
        Instance={new=function(class) return instance(class) end},task=tasks,
        require=function(module) return assert(modules[module],"Unexpected module: "..tostring(module.Name)) end,
        typeof=function(value) return if type(value)=="table" and getmetatable(value)==vmt then "Vector3" elseif type(value)=="table" and value.ClassName then "Instance" else type(value) end,
        os={clock=function() return now end},print=function() end,warn=function(message) table.insert(errors,"warning: "..tostring(message)) end},
        {__index=getfenv()})
    local function advance(seconds)
        local deadline=now+seconds
        local limit=0
        while true do
            table.sort(queue,function(a,b) return a.at<b.at end)
            if #queue==0 or queue[1].at>deadline+1e-9 then break end
            local job=table.remove(queue,1);now=job.at;limit+=1;assert(limit<100000,"scheduler runaway")
            local ok,delay=coroutine.resume(job.thread,table.unpack(job.args))
            if not ok then table.insert(errors,tostring(delay))
            elseif coroutine.status(job.thread)~="dead" then schedule(job.thread,now+(delay or .03)) end
        end
        now=deadline
        assert(#errors==0,"real Combat runtime error: "..table.concat(errors," | "))
    end
    local function character(player)
        if player.Character then player.CharacterRemoving:Fire(player.Character) end
        local char=instance("Model",player.Name.."Character",world)
        local head=instance("Part","Head",char);head.Position=Vector.new(0,5,0);head.CFrame=basis(head.Position,head.Position-Vector.zAxis)
        local body=instance("Part","UpperTorso",char);body.Position=Vector.new(0,3,-12)
        local root=instance("Part","HumanoidRootPart",char);root.Position=Vector.new(0,3,-12)
        local hum=instance("Humanoid","Humanoid",char)
        player.Character=char;player.CharacterAdded:Fire(char)
        return char,hum,root
    end
    local nextUserId=0
    local function add(name,role,loaded)
        local player=instance("Player",name,players);player.CharacterAdded=signal();player.CharacterRemoving=signal();nextUserId+=1;player.UserId=nextUserId
        -- Round owns this snapshot and sets it before publishing Results. A
        -- default zero is essential: delayed Team callbacks are not authority.
        player:SetAttribute("ZO_SurvivedRound",0)
        player.Team={Name=role or "Humans"};table.insert(list,player)
        if loaded~=false then character(player) end
        players.PlayerAdded:Fire(player);advance(0);return player
    end
    rs:SetAttribute("ZO_RoundState",if options.roundSource then "Starting" else "Preparation")
    rs:SetAttribute("ZO_RoundId",if options.roundSource then 0 else 1);rs:SetAttribute("ZO_BarricadesAvailable",true)
    local fn=assert(loadstring(COMBAT_SOURCE,"Combat.server.luau"));setfenv(fn,env);tasks.spawn(fn);advance(0)
    if options.roundSource then
        local roundEnv=setmetatable({script=instance("Script","ZombieRound")},{__index=env})
        local round=assert(loadstring(options.roundSource,"Round.server.luau"));setfenv(round,roundEnv);tasks.spawn(round)
        if options.startupSource then
            local startup=assert(loadstring(options.startupSource,"Startup.server.luau"));setfenv(startup,env);tasks.spawn(startup)
        end
        rs:SetAttribute("ZO_BarricadesReady",true);advance(0)
    end
    local function request(name,player,...) local remote=assert(rs:FindFirstChild(name),name);remote.OnServerEvent:Fire(player,...);advance(0) end
    return {rs=rs,ss=ss,world=world,players=players,internal=internal,props=props,infect=infect,push=push,damage=damage,
        errors=errors,raycasts=raycasts,add=add,character=character,advance=advance,instance=instance,
        now=function() return now end,
        ray=function(fn) raycast=fn end,
        role=function(player,role) player.Team={Name=role};advance(0) end,
        phase=function(phase) rs:SetAttribute("ZO_RoundState",phase);advance(0) end,
        fire=function(player,direction) request("ZO_FireRifle",player,"Fire",direction or -Vector.zAxis) end,
        reload=function(player) request("ZO_FireRifle",player,"Reload") end,
        melee=function(player,direction) request("ZO_Melee",player,direction or -Vector.zAxis) end,
        loadout=function(player,action,id) request("ZO_LoadoutAction",player,action,id) end,
        request=request,
        remove=function(player) local index=table.find(list,player);if index then table.remove(list,index) end;player.Parent=nil;players.PlayerRemoving:Fire(player);advance(0) end}
end
return {simulation=simulation,Vector=Vector}
end
