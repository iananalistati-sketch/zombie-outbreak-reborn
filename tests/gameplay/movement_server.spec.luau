-- Actual modules/controller with deterministic time and API doubles. Motor C0
-- and query calls are inspected; no physical character or renderer is simulated.
local Config=assert(loadstring(CONFIG_SOURCE))()
local checks=0
local function check(value,label) assert(value,label);checks+=1 end
local function near(a,b) return math.abs(a-b)<.00001 end
local vectorMeta={}
local function vector(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},vectorMeta) end
vectorMeta.__add=function(a,b) return vector(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vectorMeta.__sub=function(a,b) return vector(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
vectorMeta.__mul=function(a,b) if type(a)=='number' then a,b=b,a end;return vector(a.X*b,a.Y*b,a.Z*b) end
local frameMeta={}
local function frame(x,y,z,rx) return setmetatable({Position=vector(x,y,z),rx=rx or 0},frameMeta) end
frameMeta.__mul=function(a,b) return frame(a.Position.X+b.Position.X,a.Position.Y+b.Position.Y,a.Position.Z+b.Position.Z,a.rx+b.rx) end
function frameMeta.__index(_,key)
    if key=='ToObjectSpace' then return function(a,b) return frame(b.Position.X-a.Position.X,b.Position.Y-a.Position.Y,b.Position.Z-a.Position.Z,b.rx-a.rx) end end
end
local CFrame={new=frame,Angles=function(x) return frame(0,0,0,x) end}

local function simulation(options)
    options=options or {}
    local now=10
    local bufferFloat=buffer.create(4)
    local function signal()
        local callbacks={}
        local result={}
        function result:Connect(fn)
            local connection={}
            callbacks[connection]=fn
            function connection:Disconnect() callbacks[self]=nil end
            return connection
        end
        function result:Fire(...)
            for _,fn in table.clone(callbacks) do fn(...) end
        end
        return result
    end
    local methods={}
    local function instance(class,name,parent)
        local data={ClassName=class,Name=name or class,_children={},_attrs={},_properties={},_attributes={}}
        local object={_data=data}
        setmetatable(object,{__index=function(_,key)
            if data[key]~=nil then return data[key] end
            return methods[key] or data._children[key]
        end,__newindex=function(_,key,value)
            if class=='Humanoid' and key=='WalkSpeed' then
                buffer.writef32(bufferFloat,0,value);value=buffer.readf32(bufferFloat,0)
            end
            local previous=data[key]
            if key=='Parent' and previous~=value then
                if previous then previous._children[data.Name]=nil end
                data.Parent=value
                if value then
                    value._children[data.Name]=object
                    local node=value;while node do node.DescendantAdded:Fire(object);node=node.Parent end
                end
                object.AncestryChanged:Fire(object,value)
            else data[key]=value end
            if previous~=value and data._properties[key] then data._properties[key]:Fire() end
        end})
        object.DescendantAdded=signal();object.AncestryChanged=signal();object.Destroying=signal()
        if class=='RemoteEvent' then object.OnServerEvent=signal() end
        if class=='Part' then
            object.Size=vector(2,2,1);object.CFrame=frame();object.CanCollide=true;object.CanQuery=true;object.CanTouch=true
        end
        if class=='Motor6D' then object.C0=frame() end
        if class=='Humanoid' then object.WalkSpeed=16;object.Health=100 end
        if parent then object.Parent=parent end
        return object
    end
    function methods:IsA(class) return self.ClassName==class or class=='Instance' or self.ClassName=='Part' and class=='BasePart' end
    function methods:GetChildren() local list={};for _,value in self._children do table.insert(list,value) end;return list end
    function methods:GetDescendants()
        local list={};for _,child in self:GetChildren() do table.insert(list,child);for _,nested in child:GetDescendants() do table.insert(list,nested) end end;return list
    end
    function methods:FindFirstChild(name) return self._children[name] end
    function methods:FindFirstChildOfClass(class) for _,child in self:GetChildren() do if child:IsA(class) then return child end end end
    function methods:WaitForChild(name) return assert(self:FindFirstChild(name),self.Name..'.'..name) end
    function methods:IsDescendantOf(parent) local node=self.Parent;while node do if node==parent then return true end;node=node.Parent end;return false end
    function methods:GetAttribute(name) return self._attrs[name] end
    function methods:SetAttribute(name,value)
        local previous=self._attrs[name];self._attrs[name]=value
        if previous~=value and self._attributes[name] then self._attributes[name]:Fire() end
    end
    function methods:GetAttributeChangedSignal(name) self._attributes[name]=self._attributes[name] or signal();return self._attributes[name] end
    function methods:GetPropertyChangedSignal(name) self._properties[name]=self._properties[name] or signal();return self._properties[name] end
    function methods:Destroy() self.Destroying:Fire();self.Parent=nil end
    local world=instance('Workspace','Workspace')
    local rs=instance('ReplicatedStorage','ReplicatedStorage')
    local players=instance('Players','Players');players.PlayerAdded=signal();players.PlayerRemoving=signal()
    local list={}
    function players:GetPlayers() return table.clone(list) end
    local shared=instance('Folder','K17Gameplay',rs)
    local state=assert(loadstring(STATE_SOURCE))()
    local poseEnv=setmetatable({CFrame=CFrame,Vector3={new=vector},OverlapParams={new=function() return {} end},
        Enum={RaycastFilterType={Exclude='Exclude'}}},{__index=getfenv()})
    local poseFn=assert(loadstring(POSE_SOURCE));setfenv(poseFn,poseEnv);local pose=poseFn()
    local modules={}
    for name,value in {MovementConfig=Config,MovementState=state,MovementPose=pose} do modules[instance('ModuleScript',name,shared)]=value end
    local blocked=false
    local queries={}
    local obstacle=instance('Part','Ceiling',world)
    function world:GetPartBoundsInBox(cf,size,params)
        table.insert(queries,{cf=cf,size=size,params=params})
        return if blocked then {obstacle} else {}
    end
    local heartbeat=signal()
    local runService={Heartbeat=heartbeat}
    local script=instance('Script','Movement')
    local env=setmetatable({game={GetService=function(_,name)
        return assert(({Players=players,ReplicatedStorage=rs,RunService=runService})[name],name)
    end},workspace=world,script=script,Instance={new=function(class) return instance(class) end},
        os={clock=function() return now end},require=function(module) return assert(modules[module],module.Name) end,
        print=function() end},{__index=getfenv()})
    local function character(player,role)
        local char=instance('Model',player.Name..'Character',world)
        local root=instance('Part','HumanoidRootPart',char);root.CFrame=frame(0,3,0);root.CanCollide=false
        local head=instance('Part','Head',char);head.CFrame=frame(0,4.5,0);head.Size=vector(2,1,1)
        local torso=instance('Part',if options.r6 then 'Torso' else 'LowerTorso',char)
        local rootMotor=instance('Motor6D','Root',root);rootMotor.Part0=root;rootMotor.Part1=torso
        local joints={rootMotor}
        for _,side in {'Left','Right'} do
            local upper=instance('Part',side..'UpperLeg',char)
            local hip=instance('Motor6D',side..(if options.r6 then ' Hip' else 'Hip'),torso)
            hip.Part0=torso;hip.Part1=upper;hip.C0=frame(if side=='Left' then -.5 else .5,-1,0)
            table.insert(joints,hip)
            if not options.r6 then
                local lower=instance('Part',side..'LowerLeg',char)
                local knee=instance('Motor6D',side..'Knee',upper);knee.Part0=upper;knee.Part1=lower;table.insert(joints,knee)
            end
        end
        local hum=instance('Humanoid','Humanoid',char)
        state.setBase(hum,if role=='Zombies' then 19 else 16,now)
        player.Character=char
        return char,hum,root,rootMotor,joints
    end
    local function add(name,role)
        local player=instance('Player',name,players);player.Team={Name=role or 'Humans'}
        player.CharacterAdded=signal();player.CharacterRemoving=signal()
        local char,hum,root,rootMotor,joints=character(player,role)
        table.insert(list,player)
        return player,char,hum,root,rootMotor,joints
    end
    local player,char,hum,root,rootMotor,joints=add('Player','Humans')
    rs:SetAttribute('ZO_RoundState','Active')
    local fn=assert(loadstring(MOVEMENT_SOURCE));setfenv(fn,env);fn()
    local remote=assert(rs:FindFirstChild('ZO_MoveIntent'))
    return {state=state,rs=rs,world=world,players=players,player=player,character=char,hum=hum,root=root,
        rootMotor=rootMotor,joints=joints,queries=queries,script=script,remote=remote,
        request=function(mode,p) remote.OnServerEvent:Fire(p or player,mode) end,
        advance=function(seconds) now+=seconds or .05;heartbeat:Fire(seconds or .05) end,
        now=function() return now end,
        ceiling=function(value) blocked=value end,
        role=function(role) player.Team={Name=role};state.setBase(hum,if role=='Zombies' then 19 else 16,now) end,
        respawn=function()
            player.CharacterRemoving:Fire(player.Character)
            local c,h,r,m,j=character(player,player.Team.Name);player.CharacterAdded:Fire(c)
            return c,h,r,m,j
        end,
        instance=instance}
end

do
    local s=simulation();s.advance(.05)
    check(s.script:GetAttribute('ZO_MovementReady')==true,'actual controller registers its stance protocol')
    check(s.hum.WalkSpeed==16 and s.hum:GetAttribute('ZO_MovementMode')=='Run','normal mode preserves configured role speed')
    s.request('Walk');s.advance(.05)
    check(s.hum.WalkSpeed==8,'walking uses the server scale rather than client speed values')
    s.request('Crouch');s.advance(.2)
    check(s.hum:GetAttribute('ZO_Crouching') and s.hum.WalkSpeed==8,'crouch state is server-confirmed')
    check(s.rootMotor.C0.Position.Y<-.5 and s.joints[2].C0.Position.Y>-1,'actual rig root and hip Motor6Ds form a lower stance')
    check(s.root.Size.Y==2 and not s.root.CanCollide,'crouch does not resize root or enable a replacement collider')
    check(s.character.Head.CanCollide and s.character.Head.CanQuery and s.character.Head.CanTouch,'existing contact and query flags are preserved')
    check(#s.character:GetChildren()==8,'controller creates no replacement rig or duplicate root weld')
    s.request('Run');s.advance(.2)
    check(not s.hum:GetAttribute('ZO_Crouching') and s.hum.WalkSpeed==16,'clear headroom restores normal stance and speed')
    check(#s.queries>0 and s.queries[#s.queries].params.RespectCanCollide==true
        and s.queries[#s.queries].params.FilterDescendantsInstances[1]==s.character,'standing checks collidable geometry while excluding the owner character')
    local query=s.queries[#s.queries]
    check(near(query.cf.Position.Z,Config.CrouchForward/2)
        and near(query.size.Z,1+Config.CrouchForward+Config.StandPadding*2),
        'clearance includes the complete forward-to-standing head sweep with positive padding')
    check(near(query.cf.Position.Y,4.5-Config.CrouchDrop/2)
        and near(query.size.Y,1+Config.CrouchDrop+Config.StandPadding),
        'clearance covers the full vertical lift rather than a single head-height ray')
end

do
    local s=simulation();s.advance(.05);s.request('Crouch');s.advance(.3);s.ceiling(true)
    s.request('Run');s.advance(.1)
    check(s.hum:GetAttribute('ZO_Crouching') and s.hum:GetAttribute('ZO_StandBlocked'),'ceiling refuses untrusted stand intent')
    check(s.hum.WalkSpeed==8,'blocked stand retains the crouched speed')
    s.role('Zombies');s.advance(.1)
    check(s.hum:GetAttribute('ZO_Crouching') and near(s.hum.WalkSpeed,9.5),'infection changes role base while preserving posture under the ceiling')
    s.state.tag(s.hum,s.now(),.18,.55);s.advance(.05)
    check(near(s.hum.WalkSpeed,19*.5*.55),'confirmed hit composes zombie tag with crouched mode instead of losing either effect')
    s.ceiling(false);s.advance(.05)
    check(not s.hum:GetAttribute('ZO_Crouching') and near(s.hum.WalkSpeed,19*.55),'standing during hit tag restores current role mode without erasing suppression')
    s.advance(.2)
    check(s.hum.WalkSpeed==19,'tag expiry recovers the current zombie base speed')
end

do
    local s=simulation();s.advance(.05)
    for _,bad in {100,math.huge,{},'Sprint=100','Fly'} do s.request(bad) end
    s.advance(.05)
    check(s.hum.WalkSpeed==16,'numeric speed and unknown mode requests cannot change movement')
    s.request('Walk');s.request('Crouch');s.advance(.05)
    check(s.hum:GetAttribute('ZO_MovementMode')=='Crouch','fixed-rate maintenance coalesces repeated intent to its latest valid mode')
    s.request('Run');s.request('Crouch');s.request('Run');s.advance(.05)
    check(s.hum:GetAttribute('ZO_MovementMode')=='Run','a compressed key release cannot strand the player crouched')
    s.request('Walk');s.advance(.05)
    s.hum.WalkSpeed=23.7;local external=s.hum.WalkSpeed;s.advance(.1)
    check(s.hum.WalkSpeed==external,'idle stance maintenance does not steal an external speed write')
    s.request('Crouch');s.advance(.05)
    check(near(s.hum.WalkSpeed,external),'a later same-scale stance intent composes the adopted baseline')
    s.rs:SetAttribute('ZO_RoundState','Results');s.advance(.2)
    check(s.hum:GetAttribute('ZO_MovementMode')=='Run','round results cancels movement input')
    local speed=s.hum.WalkSpeed;s.request('Crouch');s.advance(.1)
    check(s.hum.WalkSpeed==speed,'results phase rejects new crouch requests')
end

do
    local s=simulation();s.advance(.05);s.request('Sprint');s.advance(.05)
    check(s.hum.WalkSpeed==20 and s.hum:GetAttribute('ZO_MovementMode')=='Sprint',
        'named sprint intent uses only the configured server multiplier for humans')
    local deadline=s.state.tag(s.hum,s.now(),.18,.55);s.advance(.05)
    check(near(s.hum.WalkSpeed,16*Config.SprintScale*.55),'hit containment applies while sprinting')
    s.request('Crouch');s.advance(.05)
    check(near(s.hum.WalkSpeed,16*Config.CrouchScale*.55)
        and s.hum:GetAttribute('ZO_TaggedUntil')==deadline,'sprint to crouch keeps the active tag and role baseline')
    s.ceiling(true);s.request('Sprint');s.advance(.05)
    check(s.hum:GetAttribute('ZO_Crouching') and s.hum:GetAttribute('ZO_StandBlocked')
        and near(s.hum.WalkSpeed,16*Config.CrouchScale*.55),'sprint intent cannot bypass a ceiling or the active hit effect')
    s.ceiling(false);s.advance(.05)
    check(s.hum:GetAttribute('ZO_MovementMode')=='Sprint' and s.hum.WalkSpeed==20,
        'pending sprint resumes at its configured speed once clear and the tag expires')
    s.role('Zombies');s.advance(.05)
    check(s.hum.WalkSpeed==19 and s.hum:GetAttribute('ZO_MovementMode')=='Run',
        'infection resets the prior human sprint intent to the zombie base')
    s.request('Sprint');s.advance(.05)
    check(s.hum.WalkSpeed==23.75,'zombies sprint from their own role baseline')
    s.state.tag(s.hum,s.now(),.18,.55);s.advance(.05)
    check(near(s.hum.WalkSpeed,19*Config.SprintScale*.55),'zombie sprint does not escape a fresh hit slowdown')
    s.request('Run');s.request('Sprint');s.request('Run');s.advance(.05)
    check(s.hum:GetAttribute('ZO_MovementMode')=='Run' and near(s.hum.WalkSpeed,19*.55),
        'a compressed sprint key release restores normal mode without losing its tag')
    s.advance(.2)
    check(s.hum.WalkSpeed==19,'after sprint release the tag expires to the ordinary zombie speed')
end

do
    local s=simulation();s.advance(.05);s.role('Zombies');s.advance(.05)
    s.request('Crouch');s.advance(.2)
    s.state.tag(s.hum,s.now(),.18,.55)
    check(near(s.hum.WalkSpeed,19*.5*.55),'teardown case begins with crouch and a genuine active hit tag')
    s.script:Destroy()
    check(s.rootMotor.C0.Position.Y==0 and s.hum:GetAttribute('ZO_MovementMode')=='Run'
        and near(s.hum.WalkSpeed,19*.55),'teardown restores normal posture/speed mode without clearing a live hit effect')
    s.state.step(s.hum,s.now()+.3)
    check(s.hum.WalkSpeed==19,'shared tag still expires normally after movement controller teardown')
end

do
    local s=simulation();s.advance(.05)
    s.hum.Health=0;s.request('Crouch');s.advance(.1)
    check(s.hum:GetAttribute('ZO_MovementMode')=='Run','dead characters cannot apply remote stance changes')
    s.hum.Health=100;s.role('Spectators');s.request('Crouch');s.advance(.1)
    check(s.hum:GetAttribute('ZO_MovementMode')=='Run','unknown roles cannot apply remote stance changes')
    s.role('Humans');s.character.Parent=nil;s.request('Crouch');s.advance(.1)
    check(s.hum:GetAttribute('ZO_MovementMode')=='Run','detached characters cannot move through stale remote requests')
end

do
    local s=simulation({r6=true});s.advance(.05);s.request('Crouch');s.advance(.2)
    check(s.rootMotor.C0.Position.Y<0 and s.hum:GetAttribute('ZO_Crouching'),'R6 uses its existing root and hip joints too')
    local oldHum,oldMotor=s.hum,s.rootMotor
    local _,newHum,_,newMotor=s.respawn();s.advance(.1)
    check(oldMotor.C0.Position.Y==0 and oldHum:GetAttribute('ZO_Crouching')==false,'character removal restores old pose baseline')
    check(newMotor.C0.Position.Y==0 and newHum.WalkSpeed==16,'new character receives no stale crouch pose or speed')
    s.script:Destroy()
    check(s.remote.Parent==nil and newMotor.C0.Position.Y==0 and newHum:GetAttribute('ZO_MovementMode')=='Run',
        'controller destruction releases its remote and restores the normal movement mode')
end

print(('PASS actual Movement server/state/pose: %d assertions; Roblox API doubles, physical contacts and replication require Studio'):format(checks))
