-- Actual EquipmentVisuals controller + actual shared pose adapter. These API
-- doubles advance track timelines, but do not render rigs or run Roblox physics.
local Config=assert(loadstring(CONFIG_SOURCE))()
local AimPose=assert(loadstring(AIM_POSE_SOURCE))()
local checks=0
local function check(ok,label) assert(ok,label);checks+=1 end

local function simulation(options)
    options=options or {}
    local queue,tracks,warnings={},{},{}
    local function signal()
        local callbacks={}
        local result={}
        function result:Connect(fn)
            local connection={Connected=true}
            callbacks[connection]=fn
            function connection:Disconnect() self.Connected=false;callbacks[self]=nil end
            return connection
        end
        function result:Fire(...) for connection,fn in table.clone(callbacks) do if connection.Connected then fn(...) end end end
        function result:Count() local count=0;for _ in callbacks do count+=1 end;return count end
        return result
    end
    local function flush()
        local iterations=0
        while #queue>0 do
            iterations+=1;assert(iterations<1000,"controller refresh loop")
            table.remove(queue,1)()
        end
    end
    local tasks={defer=function(fn) table.insert(queue,fn) end}
    local cf={}
    function cf:ToObjectSpace(other) return other end
    local CFrame={new=function() return cf end}
    local function loadConfig()
        local fn=assert(loadstring(PRESENTATION_CONFIG_SOURCE))
        setfenv(fn,setmetatable({CFrame=CFrame},{__index=getfenv()}))
        return fn()
    end
    local PresentationConfig=loadConfig()
    local methods={}
    local instance
    instance=function(class,name,parent)
        local data={ClassName=class,Name=name or class,_children={},_attrs={},_properties={},_attributes={},Archivable=true}
        local result={_data=data}
        setmetatable(result,{
            __index=function(_,key)
                if data[key]~=nil then return data[key] end
                if methods[key]~=nil then return methods[key] end
                return data._children[key]
            end,
            __newindex=function(_,key,value)
                local previous=data[key]
                if key=="Parent" and value~=previous then
                    if previous then
                        previous._children[data.Name]=nil;previous.ChildRemoved:Fire(result)
                        local node=previous;while node do node.DescendantRemoving:Fire(result);node=node.Parent end
                    end
                    data.Parent=value
                    if value then
                        value._children[data.Name]=result;value.ChildAdded:Fire(result)
                        local node=value;while node do node.DescendantAdded:Fire(result);node=node.Parent end
                    end
                    result.AncestryChanged:Fire(result,value)
                elseif key=="Name" and value~=previous then
                    if data.Parent then data.Parent._children[data.Name]=nil;data.Parent._children[value]=result end
                    data[key]=value
                else data[key]=value end
                if value~=previous and data._properties[key] then data._properties[key]:Fire() end
            end,
        })
        result.ChildAdded=signal();result.ChildRemoved=signal();result.DescendantAdded=signal()
        result.DescendantRemoving=signal();result.AncestryChanged=signal()
        if class=="Humanoid" then result.Health=100;result.Died=signal();result.RigType="R15" end
        if class=="Part" or class=="MeshPart" then result.CFrame=cf end
        if class=="Attachment" then result.WorldCFrame=cf end
        if parent then result.Parent=parent end
        return result
    end
    function methods:IsA(class)
        return self.ClassName==class or class=="Instance"
            or class=="BasePart" and (self.ClassName=="Part" or self.ClassName=="MeshPart")
            or class=="LuaSourceContainer" and (self.ClassName=="LocalScript" or self.ClassName=="Script" or self.ClassName=="ModuleScript")
    end
    function methods:GetChildren() local result={};for _,child in self._children do table.insert(result,child) end;return result end
    function methods:GetDescendants()
        local result={};for _,child in self:GetChildren() do table.insert(result,child);for _,nested in child:GetDescendants() do table.insert(result,nested) end end;return result
    end
    function methods:FindFirstChild(name,recursive)
        if self._children[name] then return self._children[name] end
        if recursive then for _,child in self:GetChildren() do local found=child:FindFirstChild(name,true);if found then return found end end end
        return nil
    end
    function methods:WaitForChild(name) return assert(self:FindFirstChild(name),self.Name.." missing "..name) end
    function methods:FindFirstChildOfClass(class) for _,child in self:GetChildren() do if child:IsA(class) then return child end end;return nil end
    function methods:IsDescendantOf(ancestor) local node=self.Parent;while node do if node==ancestor then return true end;node=node.Parent end;return false end
    function methods:GetAttribute(name) return self._attrs[name] end
    function methods:SetAttribute(name,value)
        local previous=self._attrs[name];self._attrs[name]=value
        if previous~=value and self._attributes[name] then self._attributes[name]:Fire() end
    end
    function methods:GetAttributeChangedSignal(name) self._attributes[name]=self._attributes[name] or signal();return self._attributes[name] end
    function methods:GetPropertyChangedSignal(name) self._properties[name]=self._properties[name] or signal();return self._properties[name] end
    function methods:Clone()
        local mapping={}
        local function copy(source)
            local clone=instance(source.ClassName,source.Name);mapping[source]=clone
            clone._data._attrs=table.clone(source._attrs)
            for _,child in source:GetChildren() do copy(child).Parent=clone end
            return clone
        end
        local result=copy(self)
        for source,clone in mapping do
            for name,value in source._data do
                if name:sub(1,1)~="_" and name~="Parent" and name~="Name" and type(value)~="function"
                    and not (type(value)=="table" and value.Connect) then clone[name]=mapping[value] or value end
            end
        end
        return result
    end
    function methods:Destroy()
        self.Destroyed=true
        for _,child in self:GetChildren() do child:Destroy() end
        self.Parent=nil
    end
    local function track(animation)
        local result=instance("AnimationTrack",animation.Name)
        result.Length=options.lateLength and 0 or 2;result.TimePosition=0;result.IsPlaying=false;result.Speed=1
        result.playCalls={};result.stopCalls=0
        function result:Play(fade,weight,speed)
            self.IsPlaying=true;self.Speed=speed or 1
            table.insert(self.playCalls,{fade=fade,weight=weight,speed=speed})
        end
        function result:AdjustSpeed(speed) self.Speed=speed end
        function result:Stop() self.IsPlaying=false;self.stopCalls+=1 end
        function result:Destroy()
            self.listenersAtDestroy=self:GetPropertyChangedSignal("Length"):Count()
            self.Destroyed=true;self.IsPlaying=false
        end
        table.insert(tracks,result)
        return result
    end
    function methods:LoadAnimation(animation) return track(animation) end
    local players=instance("Players","Players");players.PlayerAdded=signal();players.PlayerRemoving=signal()
    local rs=instance("ReplicatedStorage","ReplicatedStorage")
    local world=instance("Workspace","Workspace")
    function world:GetServerTimeNow() return 100 end
    local shared=instance("Folder","K17Gameplay",rs)
    local modules={}
    for name,value in {Config=Config,PresentationConfig=PresentationConfig,WeaponAimPose=AimPose} do modules[instance("ModuleScript",name,shared)]=value end
    local kit=instance("Folder","ZO_WeaponAssets",rs)
    local weapons=instance("Folder","Weapons",kit)
    local animations=instance("Folder","Animations",kit)
    for _,name in {"RifleAim","RifleAimDownSights","RifleReload"} do instance("Animation",name,animations) end
    local template=instance("Tool","Rifle",weapons)
    instance("Part","Handle",template)
    local model=instance("Model","AR",template)
    local primary=instance("MeshPart","Rifle",model);model.PrimaryPart=primary
    instance("Attachment","HandleAttachment",primary)
    instance("LocalScript","ExecutableMustBeRemoved",template)
    local player=instance("Player","Player",players);player.CharacterAdded=signal();player.CharacterRemoving=signal()
    player.Team={Name="Humans"};player:SetAttribute("ZO_WeaponId","Rifle");player:SetAttribute("ZO_Reloading",false)
    local character=instance("Model","Character",world);player.Character=character
    local humanoid=instance("Humanoid","Humanoid",character);humanoid.RigType=options.r6 and "R6" or "R15"
    function players:GetPlayers() return {player} end
    rs:SetAttribute("ZO_RoundState","Preparation")
    local controller=instance("Script","EquipmentVisuals")
    local services={Players=players,ReplicatedStorage=rs,RunService={IsStudio=function() return true end}}
    local enum={HumanoidRigType={R15="R15"},AnimationPriority={Action="Action",Action2="Action2"}}
    local env=setmetatable({game={GetService=function(_,name) return assert(services[name],name) end},workspace=world,script=controller,
        task=tasks,CFrame=CFrame,Enum=enum,Instance={new=function(class) return instance(class) end},typeof=function(value) return type(value) end,
        require=function(module) return assert(modules[module],module.Name) end,warn=function(message) table.insert(warnings,message) end},
        {__index=getfenv()})
    local source=assert(loadstring(EQUIPMENT_SOURCE));setfenv(source,env);source();flush()
    local function latest(name)
        for index=#tracks,1,-1 do if tracks[index].Name==name and not tracks[index].Destroyed then return tracks[index] end end
        return nil
    end
    local function advance(seconds)
        for _,value in tracks do
            if value.IsPlaying and not value.Destroyed then
                value.TimePosition+=value.Speed*seconds
                if value.Looped and value.Length>0 then value.TimePosition%=value.Length end
            end
        end
        flush()
    end
    return {player=player,character=character,humanoid=humanoid,rs=rs,world=world,players=players,
        tracks=tracks,warnings=warnings,script=controller,flush=flush,latest=latest,advance=advance}
end

do
    local s=simulation();local aim=s.latest("RifleAim");local reload=s.latest("RifleReload")
    check(s.script:GetAttribute("ZO_EquipmentVisualsReady"),"actual equipment controller starts")
    check(#s.warnings==0 and s.player:GetAttribute("ZO_WeaponVisualStatus")=="Ready","available reviewed kit produces ready world presentation: "..table.concat(s.warnings," | "))
    local tool=s.character:FindFirstChild("ZO_EquippedWeapon")
    check(tool and not tool:FindFirstChild("ExecutableMustBeRemoved"),"world tool strips executable descendants")
    check(aim.IsPlaying and aim.Speed==0 and aim.TimePosition==1,"world aim samples the neutral original-kit pose without playing its pitch sweep")
    check(aim.Looped==false,"world pitch bank is not configured as a looping idle")
    check(not reload.IsPlaying,"loading the reload track does not start a reload")
    s.advance(5)
    check(aim.TimePosition==1,"observer pose never drifts down/up as animation time advances")
    s.player:SetAttribute("ZO_ReloadEndsAt",102);s.player:SetAttribute("ZO_Reloading",true);s.flush()
    check(reload.IsPlaying and reload.Speed==1,"real reload retains ordinary timed playback rather than frozen aim behavior")
    s.advance(.5)
    check(reload.TimePosition==.5 and aim.TimePosition==1,"reload advances while the independent aim pose stays sampled")
    s.player:SetAttribute("ZO_Reloading",false);s.flush()
    check(not reload.IsPlaying and aim.TimePosition==1,"reload cancellation preserves the neutral equipped pose")
    s.player.Team={Name="Zombies"};s.flush()
    check(not s.character:FindFirstChild("ZO_EquippedWeapon"),"infection removes world gun")
    check(aim.Destroyed and reload.Destroyed and not aim.IsPlaying,"infection stops and releases kit animation tracks")
    check(aim.listenersAtDestroy==0,"length listener disconnects before animation track destruction")
    check(s.player:GetAttribute("ZO_WeaponVisualStatus")=="Idle","infected presentation reports idle")
end

do
    local s=simulation({lateLength=true});local aim=s.latest("RifleAim")
    check(aim.IsPlaying and aim.Speed==0,"unloaded aim bank cannot begin sweeping while waiting for its duration")
    aim.Length=2;s.flush()
    check(aim.TimePosition==1,"late duration availability seeks the original kit's horizontal pose")
    s.advance(4)
    check(aim.TimePosition==1,"late-loaded observer pose remains frozen")
    s.rs:SetAttribute("ZO_RoundState","Results");s.flush()
    check(aim.Destroyed and aim.listenersAtDestroy==0,"round end disconnects duration observation and destroys pose track")
    aim.Length=3;s.flush()
    check(aim.TimePosition==1 and not aim.IsPlaying,"late property updates cannot restart a disposed animation")
end

do
    local s=simulation();local oldAim=s.latest("RifleAim")
    s.rs:SetAttribute("ZO_RoundState","Results");s.flush()
    s.rs:SetAttribute("ZO_RoundState","Preparation");s.flush()
    local newAim=s.latest("RifleAim")
    check(oldAim.Destroyed and newAim~=oldAim,"new preparation uses a fresh track rather than accumulating prior animations")
    check(newAim.Speed==0 and newAim.TimePosition==1,"new round reuses the same stable kit pose")
    s.players.PlayerRemoving:Fire(s.player);s.flush()
    check(newAim.Destroyed and newAim.listenersAtDestroy==0,"player removal releases active pose and duration listener")
end

do
    local s=simulation({r6=true})
    check(#s.tracks==0 and s.character:FindFirstChild("ZO_EquippedWeapon"),"R6 keeps its mesh without attempting R15 pitch tracks")
    check(s.player:GetAttribute("ZO_WeaponVisualStatus")=="NoR15Animation","R6 limitation remains explicit")
end

print(("PASS actual EquipmentVisuals + WeaponAimPose: %d assertions; pose timelines and lifecycle with API doubles; Roblox observer rendering not executed"):format(checks))
