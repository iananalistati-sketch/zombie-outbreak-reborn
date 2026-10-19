-- The runner injects current product sources. All decisions below pass through
-- the real Combat Script; doubles record API calls without simulating Studio.
local Config=assert(loadstring(CONFIG_SOURCE))()
local Rules=assert(loadstring(RULES_SOURCE))()
local WeaponState=assert(loadstring(WEAPON_SOURCE))()
local Containment=assert(loadstring(CONTAINMENT_SOURCE))()
local LoadoutState
do
    local dependency={}
    local fn=assert(loadstring(LOADOUT_SOURCE))
    setfenv(fn,setmetatable({script={Parent={WeaponState=dependency}},require=function(module)
        assert(module==dependency,"LoadoutState only requires the real WeaponState");return WeaponState
    end},{__index=getfenv()}))
    LoadoutState=fn()
end
local checks=0
local function check(ok,label) assert(ok,label);checks+=1 end
local function near(a,b) return math.abs(a-b)<.00001 end
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
    return {Position=position,LookVector=forward,RightVector=right,UpVector=up,
        VectorToWorldSpace=function(_,v) return right*v.X+up*v.Y-forward*v.Z end}
end

local function simulation()
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
                local previous=data[key]
                if key=="Parent" then
                    if previous then previous._children[data.Name]=nil end
                    data.Parent=new
                    if new then new._children[data.Name]=value end
                else data[key]=new end
                if previous~=new and data._properties[key] then data._properties[key]:Fire() end
            end})
        if class=="RemoteEvent" then value.OnServerEvent=signal() end
        if class=="Humanoid" then value.Died=signal();value.Health=100;value.WalkSpeed=18;value.FloorMaterial="Concrete";value.MoveDirection=Vector.zero end
        if class=="Part" then
            value.Position=Vector.zero;value.CFrame=basis(Vector.zero,-Vector.zAxis)
            value.Anchored=false;value.AssemblyMass=12;value.AssemblyLinearVelocity=Vector.zero
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
    local modules={}
    for name,result in {Config=Config,Rules=Rules,WeaponState=WeaponState,LoadoutState=LoadoutState,Containment=Containment} do
        local module=instance("ModuleScript",name,shared);modules[module]=result
    end
    local heartbeat=signal()
    local services={Players=players,ReplicatedStorage=rs,ServerStorage=ss,Workspace=world,
        RunService={Heartbeat=heartbeat,IsStudio=function() return false end}}
    local env=setmetatable({game={GetService=function(_,name) return assert(services[name],name) end},workspace=world,
        Vector3=Vector,CFrame={lookAt=basis,new=function(x,y,z) return basis(Vector.new(x or 0,y or 0,z or 0),Vector.new(x or 0,y or 0,(z or 0)-1)) end},
        Enum={RaycastFilterType={Exclude="Exclude"},Material={Air="Air"}},RaycastParams={new=function() return {} end},
        Random={new=function() return {NextNumber=function(_,low,high) return ((low or 0)+(high or 1))/2 end} end},
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
        local player=instance("Player",name,players);player.CharacterAdded=signal();nextUserId+=1;player.UserId=nextUserId
        -- Round owns this snapshot and sets it before publishing Results. A
        -- default zero is essential: delayed Team callbacks are not authority.
        player:SetAttribute("ZO_SurvivedRound",0)
        player.Team={Name=role or "Humans"};table.insert(list,player)
        if loaded~=false then character(player) end
        players.PlayerAdded:Fire(player);advance(0);return player
    end
    rs:SetAttribute("ZO_RoundState","Preparation");rs:SetAttribute("ZO_RoundId",1);rs:SetAttribute("ZO_BarricadesAvailable",true)
    local fn=assert(loadstring(COMBAT_SOURCE,"Combat.server.luau"));setfenv(fn,env);tasks.spawn(fn);advance(0)
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
local function attr(player,key) return player:GetAttribute("ZO_"..key) end
local function ready(s,player) s.advance(Config.EquipSeconds+.02) end
local function twoHumans()
    local s=simulation();local first=s.add("First","Humans");local second=s.add("Second","Humans")
    return s,first,second
end
local function hit(part) return {Instance=part,Position=part.Position,Normal=Vector.yAxis} end

do
    local s,p=twoHumans()
    check(s.rs:GetAttribute("ZO_GameplayCombatReady")==true,"controller publishes Ready after installing its callbacks")
    check(attr(p,"WeaponId")=="Rifle" and attr(p,"PrimaryWeapon")=="Rifle" and attr(p,"SecondaryWeapon")=="Pistol","joining human receives primary and secondary")
    check(attr(p,"Ammo")==Config.Weapons.Rifle.Magazine and attr(p,"Reserve")==Config.Weapons.Rifle.Reserve,"starter weapon receives server-owned ammo")
    local credits=attr(p,"Credits")
    check(type(credits)=="number" and credits>=Config.Economy.StartingCredits,"starting economy is published")
    s.loadout(p,"Buy","Shotgun")
    check(attr(p,"WeaponId")=="Shotgun" and attr(p,"PrimaryWeapon")=="Shotgun","buy replaces and equips primary")
    check(attr(p,"Credits")==credits-Config.Weapons.Shotgun.Price,"server catalogue price is charged once")
    local ammo=attr(p,"Ammo");s.fire(p)
    check(attr(p,"Ammo")==ammo,"shot blocked during initial equip delay")
    ready(s,p);s.fire(p)
    check(attr(p,"Ammo")==ammo-1,"shotgun spends one shell for a complete multi-pellet shot")
    s.advance(.05);s.loadout(p,"Buy","Shotgun")
    check(attr(p,"Credits")==credits-Config.Weapons.Shotgun.Price and attr(p,"Ammo")==ammo-1,"duplicate buy neither charges nor refills")
    s.advance(.05);s.loadout(p,"Equip","Rifle")
    check(attr(p,"WeaponId")=="Shotgun","replaced primary is no longer owned")
    s.advance(.05);s.loadout(p,"Equip","Pistol")
    check(attr(p,"WeaponId")=="Pistol","owned secondary can be equipped")
    ready(s,p);s.fire(p)
    check(attr(p,"Ammo")==Config.Weapons.Pistol.Magazine,"global shot cadence survives shotgun-to-pistol swap")
    s.advance(Config.Weapons.Shotgun.FireInterval);s.fire(p)
    check(attr(p,"Ammo")==Config.Weapons.Pistol.Magazine-1,"secondary fires after previous weapon cadence completes")
    s.advance(.05);s.loadout(p,"Equip","Primary");ready(s,p)
    check(attr(p,"WeaponId")=="Shotgun" and attr(p,"Ammo")==ammo-1,"slot selection preserves primary magazine")
    s.loadout(p,"Equip","Secondary");ready(s,p)
    check(attr(p,"WeaponId")=="Pistol" and attr(p,"Ammo")==Config.Weapons.Pistol.Magazine-1,"switching back preserves secondary magazine")
end

do
    local s,p=twoHumans();ready(s,p);s.fire(p)
    local ammo=attr(p,"Ammo");local reserve=attr(p,"Reserve")
    s.advance(.05);s.reload(p)
    check(attr(p,"Reloading")==true and attr(p,"ReloadEndsAt")>s.world:GetServerTimeNow(),"reload publishes a future server-time deadline")
    s.advance(Config.Weapons.Rifle.ReloadSeconds-.1)
    check(attr(p,"Ammo")==ammo and attr(p,"Reserve")==reserve,"incomplete reload grants no ammunition")
    s.fire(p);check(attr(p,"Ammo")==ammo,"reload denies fire before completion")
    s.advance(.2)
    check(attr(p,"Reloading")==false and attr(p,"Ammo")==Config.Weapons.Rifle.Magazine,"scheduled reload completes without another input")
    check(attr(p,"Reserve")==reserve-1,"reload transfers only missing rounds out of reserve")
    s.fire(p);s.advance(.05);s.reload(p);s.advance(.1);s.loadout(p,"Equip","Pistol")
    check(attr(p,"Reloading")==false,"switching weapons cancels in-progress reload")
    s.advance(Config.Weapons.Rifle.ReloadSeconds+.1);s.loadout(p,"Equip","Rifle");ready(s,p)
    check(attr(p,"Ammo")==Config.Weapons.Rifle.Magazine-1,"cancelled old reload cannot refill an unequipped weapon later")
    s.reload(p);s.advance(.05);s.role(p,"Zombies")
    check(attr(p,"Reloading")==false,"infection/role change cancels reload")
    s.advance(Config.Weapons.Rifle.ReloadSeconds+.1)
    check(attr(p,"Ammo")==Config.Weapons.Rifle.Magazine-1,"infected player never completes human reload")
end

do
    local s,p=twoHumans();ready(s,p);s.fire(p);s.advance(.05);s.reload(p);s.advance(Config.Weapons.Rifle.ReloadSeconds+.1)
    local credits=attr(p,"Credits");local ammo=attr(p,"Ammo")
    s.loadout(p,"Ammo")
    check(attr(p,"Credits")==credits-Config.Economy.AmmoPrice and attr(p,"Reserve")==Config.Weapons.Rifle.Reserve,"ammo purchase charges and fills reserve")
    check(attr(p,"Ammo")==ammo,"ammo purchase leaves magazine alone")
    s.advance(.05);s.loadout(p,"Ammo")
    check(attr(p,"Credits")==credits-Config.Economy.AmmoPrice,"full reserve cannot charge repeated purchase")
    s.phase("Active");s.advance(.05);s.loadout(p,"Buy","SMG")
    check(attr(p,"PrimaryWeapon")=="Rifle","live round blocks purchasing a primary")
    s.advance(.05);s.fire(p);s.advance(.05);s.reload(p);s.advance(Config.Weapons.Rifle.ReloadSeconds+.1);s.loadout(p,"Ammo")
    check(attr(p,"Reserve")==Config.Weapons.Rifle.Reserve-1,"live round blocks reserve purchase")
end

do
    local s,p=twoHumans();local z=s.add("Target","Zombies")
    local hum=z.Character:FindFirstChildOfClass("Humanoid");hum.Health=1000
    s.loadout(p,"Buy","Shotgun");ready(s,p);s.phase("Active")
    local before=attr(p,"Ammo")
    s.ray(function() return hit(z.Character.UpperTorso) end);s.fire(p)
    check(#s.raycasts==Config.Weapons.Shotgun.Pellets,"shotgun traces every server-owned pellet")
    check(attr(p,"Ammo")==before-1,"all shotgun raycasts cost exactly one shell")
    check(#hum._calls==1 and near(hum._calls[1][1],Config.Weapons.Shotgun.Damage*Config.Weapons.Shotgun.Pellets),"pellets hitting one character aggregate into one damage operation")
    check(#z.Character.HumanoidRootPart._calls==1,"pellets aggregate into one containment impulse per character")
    for _,ray in s.raycasts do
        check(ray.params.FilterType=="Exclude" and ray.params.FilterDescendantsInstances[1]==p.Character,"each ray excludes the shooter's own character")
    end
    check(z.Character.HumanoidRootPart.AssemblyLinearVelocity.Magnitude>0,"living zombie receives server-owned shot containment")
    check(hum.WalkSpeed<18,"confirmed hits briefly tag zombie movement")
    s.advance(Config.Containment.TagSeconds+.1)
    check(near(hum.WalkSpeed,18),"tag expires and restores the movement baseline")
    local wall=s.instance("Part","OpaqueWall",s.world)
    local health=hum.Health;s.advance(Config.Weapons.Shotgun.FireInterval);s.ray(function() return hit(wall) end);s.fire(p)
    check(hum.Health==health,"wall as first raycast hit prevents damage through the obstacle")
    check(#s.push._calls==0,"ordinary architecture never receives a barricade push callback")
end

do
    local s,p=twoHumans();s.loadout(p,"Buy","Shotgun");ready(s,p)
    local prop=s.instance("Model","TestCrate",s.props);local hull=s.instance("Part","Hull",prop)
    s.ray(function() return hit(hull) end);s.fire(p)
    check(#s.push._calls==1,"all pellets hitting one prop aggregate into one push callback")
    check(s.push._calls[1][1]==p and s.push._calls[1][2]==hull,"private push callback carries shooter and actual hit part")
    check(near(s.push._calls[1][4],Config.Weapons.Shotgun.PropScale),"full volley uses one configured prop impulse instead of seven full impulses")
    check(#s.damage._calls==0,"human bullets never invoke zombie barricade damage")
    s.advance(Config.Weapons.Shotgun.FireInterval);s.rs:SetAttribute("ZO_BarricadesAvailable",false);s.fire(p)
    check(#s.push._calls==1,"unavailable barricade service rejects further push callbacks")
end

do
    local s,p=twoHumans();local zombie=s.add("MixedTarget","Zombies")
    local hum=zombie.Character:FindFirstChildOfClass("Humanoid");hum.Health=1000
    local propA=s.instance("Model","CrateA",s.props);local hullA=s.instance("Part","Hull",propA)
    local propB=s.instance("Model","CrateB",s.props);local hullB=s.instance("Part","Hull",propB)
    local wall=s.instance("Part","Wall",s.world)
    local hits={zombie.Character.UpperTorso,hullA,hullB,wall,zombie.Character.Head,hullA,zombie.Character.UpperTorso}
    s.loadout(p,"Buy","Shotgun");ready(s,p);s.phase("Active")
    s.ray(function(_,_,_,index) return hit(hits[index]) end);s.fire(p)
    check(#hum._calls==1 and near(hum._calls[1][1],Config.Weapons.Shotgun.Damage*4),"mixed pellets preserve each hitgroup multiplier when aggregating one character")
    check(#s.push._calls==2,"mixed pellets touching two different props produce exactly two pushes")
    local pushed={}
    for _,call in s.push._calls do pushed[call[2]]=(pushed[call[2]] or 0)+1 end
    check(pushed[hullA]==1 and pushed[hullB]==1,"repeated hull hits cannot multiply a prop impulse")
    for _,call in s.push._calls do
        local fraction=if call[2]==hullA then 2/Config.Weapons.Shotgun.Pellets else 1/Config.Weapons.Shotgun.Pellets
        check(near(call[4],Config.Weapons.Shotgun.PropScale*fraction),"partial pellet coverage scales prop impulse to actual contact count")
    end
    check(attr(p,"Ammo")==Config.Weapons.Shotgun.Magazine-1,"mixed target processing still consumes only one shell")
end

do
    local s,p,teammate=twoHumans();ready(s,p);s.phase("Active")
    local hum=teammate.Character.Humanoid;local health=hum.Health;local credits=attr(p,"Credits")
    s.ray(function() return hit(teammate.Character.Head) end);s.fire(p)
    check(hum.Health==health and #hum._calls==0,"human bullets never damage a teammate")
    check(hum.WalkSpeed==18 and #teammate.Character.HumanoidRootPart._calls==0,"human teammates receive neither zombie tag nor containment impulse")
    check(attr(p,"Credits")==credits,"friendly fire cannot generate economy rewards")
end

do
    local s,p=twoHumans();ready(s,p);local before=attr(p,"Ammo")
    local invalid={Vector.new(0/0,0,-1),Vector.new(math.huge,0,0),Vector.new(0,0,-2),Vector.new(0,0,1),"forward",42,{}}
    for _,direction in invalid do s.fire(p,direction);s.advance(.05) end
    check(attr(p,"Ammo")==before and #s.raycasts==0,"nonfinite, nonunit, backward and wrong-type directions never fire")
    s.request("ZO_FireRifle",p,"Exploit",-Vector.zAxis)
    check(attr(p,"Ammo")==before,"unknown fire action has no state effect")
    local credits=attr(p,"Credits");s.loadout(p,"Buy",0/0);s.advance(.05);s.loadout(p,"Equip",{});s.advance(.05);s.loadout(p,"Unknown","LMG")
    check(attr(p,"WeaponId")=="Rifle" and attr(p,"Credits")==credits,"invalid ids, types and actions preserve inventory and credits")
    s.advance(.05);s.fire(p)
    for _=1,20 do s.fire(p) end
    check(attr(p,"Ammo")==before-1,"same-tick fire flood admits only one shot")
    p:SetAttribute("ZO_BarricadeSelection","TestCrate");s.advance(.2);s.fire(p)
    check(attr(p,"Ammo")==before-1,"selecting barricades prevents shooting")
    p:SetAttribute("ZO_BarricadeSelection",nil);s.role(p,"Zombies");s.advance(.1)
    local zombieAmmo=attr(p,"Ammo");s.fire(p);s.loadout(p,"Buy","Shotgun");s.advance(.05);s.loadout(p,"Equip","Pistol");s.advance(.05);s.loadout(p,"Ammo")
    check(attr(p,"Ammo")==zombieAmmo and attr(p,"WeaponId")=="Rifle" and attr(p,"Credits")==credits,"zombies cannot fire, buy, equip or purchase ammunition")
    s.role(p,"Spectators");s.advance(.1);s.fire(p)
    check(attr(p,"Ammo")==zombieAmmo,"spectators cannot fire")
    s.role(p,"Humans");p.Character.Humanoid.Health=0;s.advance(.1)
    local deadAmmo=attr(p,"Ammo");s.fire(p);s.loadout(p,"Buy","SMG")
    check(attr(p,"Ammo")==deadAmmo and attr(p,"PrimaryWeapon")=="Rifle","dead human cannot fire or buy")
end

do
    local s,human=twoHumans();local zombie=s.add("Attacker","Zombies");s.phase("Active")
    local credits=attr(zombie,"Credits");s.ray(function() return hit(human.Character.UpperTorso) end)
    s.infect.OnInvoke=function() return false end;s.melee(zombie)
    check(#s.infect._calls==1 and attr(zombie,"Credits")==credits,"rejected infection callback awards no credits")
    s.advance(Config.Melee.Cooldown+.01);s.infect.OnInvoke=function() return true end;s.melee(zombie)
    check(#s.infect._calls==2 and attr(zombie,"Credits")==credits+Config.Economy.InfectionReward,"accepted server infection awards attacker once")
    s.melee(zombie)
    check(#s.infect._calls==2 and attr(zombie,"Credits")==credits+Config.Economy.InfectionReward,"melee flood cannot duplicate infection or reward")
    s.advance(Config.Melee.Cooldown+.01);s.melee(human)
    check(#s.infect._calls==2,"human cannot call zombie infection melee")
    local prop=s.instance("Model","TestCrate",s.props);local hull=s.instance("Part","Hull",prop)
    s.ray(function() return hit(hull) end);s.melee(zombie)
    check(#s.damage._calls==1 and s.damage._calls[1][1]==zombie,"valid zombie melee delegates prop destruction to authoritative barricade service")
    s.phase("Preparation");s.advance(Config.Melee.Cooldown+.01);s.melee(zombie)
    check(#s.damage._calls==1,"zombie cannot damage defenses during preparation")
end

do
    local s,p=twoHumans();local zombie=s.add("LowHealth","Zombies");s.phase("Active");ready(s,p)
    local hum=zombie.Character:FindFirstChildOfClass("Humanoid");hum.Health=1
    s.ray(function() return hit(zombie.Character.UpperTorso) end)
    local credits=attr(p,"Credits");s.fire(p)
    check(hum.Health==0 and attr(p,"Credits")==credits+Config.Economy.KillReward,"confirmed zombie death awards killer")
    s.advance(Config.Weapons.Rifle.FireInterval+.01);s.fire(p)
    check(attr(p,"Credits")==credits+Config.Economy.KillReward,"shooting the same corpse never duplicates kill reward")
end

do
    local s,p=twoHumans();ready(s,p);local zombie=s.add("FastZombie","Zombies");s.phase("Active")
    local root=zombie.Character.HumanoidRootPart;root.AssemblyLinearVelocity=Vector.new(200,30,-180)
    local oldHum=zombie.Character:FindFirstChildOfClass("Humanoid");s.ray(function() return hit(zombie.Character.Head) end);s.fire(p)
    local velocity=root.AssemblyLinearVelocity
    check(math.sqrt(velocity.X*velocity.X+velocity.Z*velocity.Z)<=Config.Containment.HorizontalCap+.001,"repeated hits clamp total horizontal zombie speed")
    check(velocity.Y<=Config.Containment.UpwardCap+.001,"shot containment cannot launch zombie vertically beyond cap")
    local _,newHum=s.character(zombie);newHum.WalkSpeed=23;s.advance(Config.Containment.TagSeconds+.1)
    check(newHum.WalkSpeed==23,"old hit tag cannot overwrite the replacement character's movement")
    check(oldHum~=newHum,"respawn scenario replaces the actual tagged humanoid")
end

do
    local s,p=twoHumans();local zombie=s.add("RetagTarget","Zombies");s.phase("Active");ready(s,p)
    local hum=zombie.Character.Humanoid;hum.Health=1000
    s.ray(function() return hit(zombie.Character.UpperTorso) end);s.fire(p)
    s.advance(Config.Weapons.Rifle.FireInterval+.01);s.fire(p)
    s.advance(Config.Containment.TagSeconds-Config.Weapons.Rifle.FireInterval)
    check(hum.WalkSpeed<18,"second confirmed hit extends tag beyond the first shot expiry")
    s.advance(Config.Containment.TagSeconds+.1)
    check(near(hum.WalkSpeed,18),"repeated tags restore the original movement baseline once")
end

do
    local s,p=twoHumans();local zombie=s.add("OtherMovementEffect","Zombies");s.phase("Active");ready(s,p)
    local hum=zombie.Character.Humanoid;hum.Health=1000
    s.ray(function() return hit(zombie.Character.UpperTorso) end);s.fire(p)
    hum.WalkSpeed=23
    s.advance(Config.Containment.TagSeconds+.1)
    check(hum.WalkSpeed==23,"tag expiry never overwrites another system's newer movement speed")
    s.advance(Config.Weapons.Rifle.FireInterval+.01);s.fire(p)
    check(near(hum.WalkSpeed,23*Config.Containment.TagWalkScale),"new confirmed hit tags the changed baseline instead of restoring stale speed")
    s.advance(Config.Containment.TagSeconds+.1)
    check(hum.WalkSpeed==23,"new speed baseline survives the next tag expiry")
end

do
    local s,p=twoHumans();local initial=attr(p,"Credits")
    s.phase("Active");s.phase("Preparation")
    check(attr(p,"Credits")==initial,"replaying Preparation with the same RoundId does not grant round income again")
    s.rs:SetAttribute("ZO_RoundId",2);s.advance(0)
    check(attr(p,"Credits")==initial+Config.Economy.RoundIncome,"new RoundId grants exactly one income even when phase is already Preparation")
    s.phase("Active");s.phase("Preparation")
    check(attr(p,"Credits")==initial+Config.Economy.RoundIncome,"duplicate round transition cannot duplicate new-round income")
    p:SetAttribute("ZO_SurvivedRound",2)
    s.rs:SetAttribute("ZO_LastWinner","Humans");s.phase("Active");s.phase("Results")
    local rewarded=attr(p,"Credits")
    check(rewarded==initial+Config.Economy.RoundIncome+Config.Economy.SurvivalReward,"living human receives survival reward at Results")
    s.phase("Waiting");s.phase("Results")
    check(attr(p,"Credits")==rewarded,"repeated Results for same RoundId cannot duplicate survival reward")
    s.remove(p);local count=#s.raycasts;local removedAmmo=attr(p,"Ammo")
    s.advance(.2);s.fire(p);s.loadout(p,"Buy","SMG");s.loadout(p,"Equip","Pistol")
    check(#s.raycasts==count and attr(p,"Ammo")==removedAmmo and attr(p,"Credits")==rewarded,"disconnected player's stale remote events cannot recreate inventory or fire")
end

do
    local s,p=twoHumans();s.phase("Active")
    local credits=attr(p,"Credits")
    -- Roblox signals may execute after Round has published Results AND moved
    -- survivors to Lobby. Exercise the ordering without flushing in between.
    p:SetAttribute("ZO_SurvivedRound",1)
    s.rs:SetAttribute("ZO_LastWinner","Humans")
    s.rs:SetAttribute("ZO_RoundState","Results")
    p.Team={Name="Lobby"};s.advance(0)
    check(attr(p,"Credits")==credits+Config.Economy.SurvivalReward,"deferred Results/Team ordering still rewards the just-surviving human once")
    s.phase("Waiting");s.phase("Results")
    check(attr(p,"Credits")==credits+Config.Economy.SurvivalReward,"Results and Team hooks cannot double-pay a survivor")
end

do
    local s,p=twoHumans();s.phase("Active");local credits=attr(p,"Credits")
    p.Character.Humanoid:TakeDamage(1000);s.advance(0)
    s.rs:SetAttribute("ZO_LastWinner","Humans");s.phase("Results")
    check(attr(p,"Credits")==credits,"dead human never receives a survival reward")
end

do
    local s,p=twoHumans();s.phase("Active");local credits=attr(p,"Credits")
    -- Infection and Round cleanup can enqueue several Team notifications before
    -- Combat sees any of them. previousRoles can still say Human in every hook.
    p.Team={Name="Zombies"}
    p:SetAttribute("ZO_SurvivedRound",0)
    s.rs:SetAttribute("ZO_LastWinner","Humans")
    s.rs:SetAttribute("ZO_RoundState","Results")
    p.Team={Name="Lobby"};s.advance(0)
    check(attr(p,"Credits")==credits,"infected player with snapshot zero gets no survival reward despite stale Human role callbacks")
    s.phase("Waiting");s.phase("Results")
    check(attr(p,"Credits")==credits,"repeated Results never turn snapshot zero into a reward")
end

do
    local s,p=twoHumans();s.phase("Active");s.rs:SetAttribute("ZO_RoundId",2);s.advance(0)
    local credits=attr(p,"Credits")
    p:SetAttribute("ZO_SurvivedRound",1)
    s.rs:SetAttribute("ZO_LastWinner","Humans");s.phase("Results")
    check(attr(p,"Credits")==credits,"a survival snapshot from another round cannot authorize current-round income")
    s.phase("Waiting");p:SetAttribute("ZO_SurvivedRound","2");s.phase("Results")
    check(attr(p,"Credits")==credits,"string-coerced round snapshot is rejected")
end

do
    local s,p=twoHumans();local zombie=s.add("ChangingRole","Zombies");s.phase("Active");ready(s,p)
    local hum=zombie.Character.Humanoid;hum.Health=1000
    s.ray(function() return hit(zombie.Character.UpperTorso) end);s.fire(p)
    zombie.Team={Name="Humans"};hum.WalkSpeed=16;s.advance(0)
    s.advance(Config.Containment.TagSeconds+.1)
    check(hum.WalkSpeed==16,"role transition with a new movement baseline never receives an obsolete zombie-speed restore")
end

do
    local s=simulation();local unloaded=s.add("StillLoading","Humans",false)
    local credits=attr(unloaded,"Credits");local ammo=attr(unloaded,"Ammo")
    s.loadout(unloaded,"Buy","Shotgun");s.fire(unloaded);s.loadout(unloaded,"Equip","Pistol")
    check(attr(unloaded,"Credits")==credits and attr(unloaded,"Ammo")==ammo and #s.raycasts==0,"unloaded character cannot buy, equip or shoot before ready")
    s.character(unloaded);s.advance(.5);s.fire(unloaded)
    check(attr(unloaded,"Ammo")==Config.Weapons.Rifle.Magazine-1,"character becoming ready resumes server-owned combat")
end

print(("PASS actual Combat controller: %d assertions; inventory, economy, pellet aggregation, timers, authority and containment (Roblox API doubles)"):format(checks))
