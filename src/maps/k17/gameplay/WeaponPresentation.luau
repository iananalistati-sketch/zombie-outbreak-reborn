--!nonstrict
-- Roblox Weapons Kit presentation, adapted from the shipped BaseWeapon and
-- BulletWeapon modules. See third_party/roblox-weapon-kit for original sources
-- and Roblox Limited Use License. This module has no damage, input or hit RPCs.
-- Reused: handle weld (BaseWeapon lines 135-152), sound cloning (387-411),
-- bolt tween (BulletWeapon 141-158), shot sound/bolt (165-192), muzzle (347-361).
-- Integration glue: camera placement, visibility, cancellation and FX dispatch.
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local RS=game:GetService("ReplicatedStorage")
local PresentationConfig=require(script.Parent.PresentationConfig)
local localRandom=Random.new()
local Presentation={}
Presentation.__index=Presentation
local worldPresentations=setmetatable({},{__mode="k"})
local soundNames={
    Fired={"Fired","FiredSound","FireSound"}, Reload={"Reload","ReloadSound"},
    Equip={"Equip","EquipSound"}, BoltOpenSound={"BoltOpenSound","BoltOpen"},
    BoltCloseSound={"BoltCloseSound","BoltClose"},
}
local function findSound(instance,name)
    for _,candidate in soundNames[name] or {name} do
        local sound=instance:FindFirstChild(candidate,true)
        if sound and sound:IsA("Sound") then return sound end
    end
    return nil
end

local function bind(instance,id)
    local self=setmetatable({instance=instance,sounds={},configValues={},flashSequence=0,shotSequence=0,destroyed=false},Presentation)
    self.id=id or instance:GetAttribute("ZO_WeaponId") or instance.Name
    self.settings=PresentationConfig.get(self.id)
    self.connections={}
    local config=instance:FindFirstChild("Configuration")
    if config then
        for _,value in config:GetChildren() do
            if value:IsA("ValueBase") then self.configValues[value.Name]=value.Value end
        end
    end
    for key,name in {
        tipAttach="TipAttachment",boltMotor="BoltMotor",boltMotorStart="BoltMotorStart",
        boltMotorTarget="BoltMotorTarget",muzzleFlash0="MuzzleFlash0",muzzleFlash1="MuzzleFlash1",
        muzzleFlashBeam="MuzzleFlash",
    } do self[key]=instance:FindFirstChild(name,true) end
    if self.muzzleFlashBeam and not self.muzzleFlashBeam:IsA("Beam") then self.muzzleFlashBeam=nil end
    if self.muzzleFlashBeam then self.muzzleFlashBeam.Enabled=false end
    return self
end

function Presentation:getConfigValue(valueName,defaultValue)
    if self.configValues[valueName]~=nil then return self.configValues[valueName] end
    return defaultValue
end

-- BaseWeapon:tryPlaySound. The original clones and varies playback pitch;
-- Debris replaces its wait(TimeLength) so an unloaded Sound is not destroyed at 0s.
function Presentation:tryPlaySound(soundName,playbackSpeedRange)
    playbackSpeedRange=playbackSpeedRange or 0
    local soundTemplate=self.sounds[soundName]
    if not soundTemplate then
        soundTemplate=findSound(self.instance,soundName)
        self.sounds[soundName]=soundTemplate
    end
    if not soundTemplate or not soundTemplate:IsA("Sound") then return end
    local sound=soundTemplate:Clone()
    sound.PlaybackSpeed=math.max(.05,sound.PlaybackSpeed+localRandom:NextNumber(-playbackSpeedRange*.5,playbackSpeedRange*.5))
    sound.Volume*=if soundName=="Reload" then self.settings.ReloadVolume else self.settings.FireVolume
    sound.RollOffMinDistance=8;sound.RollOffMaxDistance=self.settings.SoundDistance
    sound.Parent=soundTemplate.Parent
    sound:Play()
    Debris:AddItem(sound,math.max(3,sound.TimeLength/math.max(.01,sound.PlaybackSpeed)+.25))
    return sound
end

-- BulletWeapon:animateBoltAction, using the imported motor and target attachments.
function Presentation:animateBoltAction(isOpen)
    if self.destroyed or not self.boltMotor or not self.boltMotor:IsA("Motor6D")
        or not self.boltMotorStart or not self.boltMotorTarget then return end
    if self.boltTween then self.boltTween:Cancel() end
    if isOpen then self:tryPlaySound("BoltOpenSound") else self:tryPlaySound("BoltCloseSound") end
    local actionMoveTime=isOpen and self:getConfigValue("ActionOpenTime",.025) or self:getConfigValue("ActionCloseTime",.075)
    local targetCFrame=isOpen and self.boltMotorTarget.CFrame or self.boltMotorStart.CFrame
    local boltTween=TweenService:Create(self.boltMotor,TweenInfo.new(actionMoveTime,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),{C0=targetCFrame})
    self.boltTween=boltTween
    boltTween:Play()
    boltTween.Completed:Wait()
end

function Presentation:fire()
    if self.destroyed or not self.instance.Parent then return end
    if self.lastFireSound then self.lastFireSound:Stop() end
    self.lastFireSound=self:tryPlaySound("Fired",self:getConfigValue("FiredPlaybackSpeedRange",.1))
    self.shotSequence+=1
    local sequence=self.shotSequence
    if self.boltMotor then
        task.spawn(function()
            self:animateBoltAction(true)
            task.wait(self:getConfigValue("ActionOpenTime",.025))
            if not self.destroyed and self.instance.Parent and sequence==self.shotSequence then self:animateBoltAction(false) end
        end)
    end
    -- BulletWeapon:simulateProjectile muzzle block. Attachments/texture are original.
    if self.tipAttach and self.muzzleFlash0 and self.muzzleFlash1 and self.muzzleFlashBeam then
        local flashRotation=localRandom:NextNumber(self:getConfigValue("MuzzleFlashRotation0",-math.pi),self:getConfigValue("MuzzleFlashRotation1",math.pi))
        local flashSize=localRandom:NextNumber(self:getConfigValue("MuzzleFlashSize0",1),self:getConfigValue("MuzzleFlashSize1",1))
        local baseCFrame=self.tipAttach.CFrame*CFrame.Angles(0,0,flashRotation)
        self.muzzleFlash0.CFrame=baseCFrame*CFrame.new(flashSize*-.5,0,0)*CFrame.Angles(0,math.pi,0)
        self.muzzleFlash1.CFrame=baseCFrame*CFrame.new(flashSize*.5,0,0)*CFrame.Angles(0,math.pi,0)
        self.muzzleFlashBeam.Enabled=true
        self.muzzleFlashBeam.Width0=flashSize
        self.muzzleFlashBeam.Width1=flashSize
        self.flashSequence+=1
        local flashSequence=self.flashSequence
        task.delay(self:getConfigValue("MuzzleFlashTime",.03),function()
            if not self.destroyed and flashSequence==self.flashSequence then self.muzzleFlashBeam.Enabled=false end
        end)
    end
end

local function alignReload(self,remaining)
    if not remaining or remaining<=0 then return end
    self.reloadDeadline=os.clock()+remaining
    if self.reloadSound and self.reloadSound.TimeLength>0 then
        self.reloadSound.TimePosition=math.max(0,self.reloadSound.TimeLength-remaining)
    end
    local track=self.tracks and self.tracks.Reload
    if track and track.Length>0 then track:AdjustSpeed(math.clamp(track.Length/remaining,.2,5)) end
end

function Presentation:setReloading(reloading,remaining)
    if reloading==self.reloading then
        -- The boolean and deadline can arrive in separate replication packets.
        if reloading and remaining and remaining>0
            and (not self.reloadDeadline or math.abs(self.reloadDeadline-(os.clock()+remaining))>.15) then
            alignReload(self,remaining)
        end
        return
    end
    self.reloading=reloading
    self.reloadDeadline=nil;self.idleStarted=false
    if self.reloadSound then self.reloadSound:Stop();self.reloadSound:Destroy();self.reloadSound=nil end
    if reloading and not self.destroyed then
        self.reloadSound=self:tryPlaySound("Reload")
        if self.reloadSound and not self.reloadSound.IsLoaded then
            local sound=self.reloadSound
            sound.Loaded:Once(function()
                if self.reloading and self.reloadSound==sound and self.reloadDeadline then
                    sound.TimePosition=math.max(0,sound.TimeLength-math.max(0,self.reloadDeadline-os.clock()))
                end
            end)
        end
    end
    if self.tracks then
        local track=if reloading then self:getTrack("Reload") else self.tracks.Reload
        if track then
            if reloading then
                for _,kind in {"Aim","AimDownSights"} do
                    local idle=self.tracks[kind]
                    if idle then idle:Stop(.08) end
                end
                local speed=if remaining and remaining>.1 and track.Length>0 then track.Length/remaining else 1
                track:Play(.08,1,math.clamp(speed,.2,5))
            else track:Stop(.12) end
        end
    end
    if reloading then alignReload(self,remaining) end
end

function Presentation:stop()
    self.shotSequence+=1;self.flashSequence+=1
    self:setReloading(false)
    if self.lastFireSound then self.lastFireSound:Stop() end
    if self.boltTween then self.boltTween:Cancel() end
    if self.muzzleFlashBeam then self.muzzleFlashBeam.Enabled=false end
    if self.boltMotor and self.boltMotorStart then self.boltMotor.C0=self.boltMotorStart.CFrame end
    if self.tracks then for _,track in self.tracks do if track then track:Stop(.1) end end end
    self.idleStarted=false
end

local armNames={RightUpperArm=true,RightLowerArm=true,RightHand=true,LeftUpperArm=true,LeftLowerArm=true,LeftHand=true}
local function placeArms(arms,rootCFrame)
    arms.root.CFrame=rootCFrame
    for _,joint in arms.joints do
        joint.Part1.CFrame=joint.Part0.CFrame*joint.C0*joint.Transform*joint.C1:Inverse()
    end
    for part,offset in arms.disconnected do part.CFrame=rootCFrame*offset end
end

local function copyArms(character,parent,zombie)
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.RigType~=Enum.HumanoidRigType.R15 then return nil,"NoR15Arms" end
    local archivable=character.Archivable
    character.Archivable=true
    local ok,rig=pcall(function() return character:Clone() end)
    character.Archivable=archivable
    if not ok or not rig then return nil,"CloneUnavailable" end
    rig.Name="ZO_FirstPersonArms"
    for _,descendant in rig:GetDescendants() do
        if descendant:IsA("LuaSourceContainer") or descendant:IsA("Tool") or descendant:IsA("Accessory")
            or descendant:IsA("Humanoid") or descendant:IsA("AnimationController") or descendant:IsA("Sound") then
            descendant:Destroy()
        end
    end
    local root=rig:FindFirstChild("HumanoidRootPart")
    local hand=rig:FindFirstChild("RightHand")
    if not root or not root:IsA("BasePart") or not hand or not hand:IsA("BasePart") then
        rig:Destroy();return nil,"IncompleteR15Rig"
    end
    local parts,motors,offsets={},{},{}
    for _,part in rig:GetDescendants() do
        if part:IsA("BasePart") then
            offsets[part]=root.CFrame:ToObjectSpace(part.CFrame)
            -- AnimationController writes Motor6D.Transform; positioning the cloned
            -- parts explicitly avoids a one-physics-frame lag behind the camera.
            part.Anchored=true;part.CanCollide=false;part.CanQuery=false;part.CanTouch=false
            part.Massless=true;part.CastShadow=false
            if not armNames[part.Name] then part.Transparency=1
            elseif zombie then part.Color=Color3.fromRGB(112,130,104) end
            part.LocalTransparencyModifier=1
            table.insert(parts,part)
        elseif part:IsA("Motor6D") then
            if part.Part0 and part.Part1 and part.Part0:IsDescendantOf(rig) and part.Part1:IsDescendantOf(rig) then
                part.Transform=CFrame.identity
                table.insert(motors,part)
                if zombie and (part.Name=="LeftShoulder" or part.Name=="RightShoulder") then
                    -- Real R15 arms, posed forward; no placeholder claw geometry.
                    part.C0*=CFrame.Angles(math.rad(78),0,if part.Name=="LeftShoulder" then -.12 else .12)
                end
            else part:Destroy() end
        end
    end
    local ordered,connected={}, {[root]=true}
    for _=1,#motors do
        local progress=false
        for index=#motors,1,-1 do
            local motor=motors[index]
            if connected[motor.Part0] then
                connected[motor.Part1]=true;table.insert(ordered,motor);table.remove(motors,index);progress=true
            end
        end
        if not progress then break end
    end
    local disconnected={}
    for part,offset in offsets do if not connected[part] then disconnected[part]=offset end end
    local controller=Instance.new("AnimationController");controller.Name="ViewmodelAnimations";controller.Parent=rig
    local animator=Instance.new("Animator");animator.Parent=controller
    local head=rig:FindFirstChild("Head")
    local headOffset=if head and head:IsA("BasePart") then root.CFrame:ToObjectSpace(head.CFrame) else CFrame.new(0,2.5,0)
    local arms={model=rig,root=root,hand=hand,parts=parts,animator=animator,headOffset=headOffset,
        joints=ordered,disconnected=disconnected}
    rig.PrimaryPart=root;placeArms(arms,CFrame.new(0,-10000,0));rig.Parent=parent
    return arms,"Ready"
end

function Presentation:getTrack(kind)
    if not self.arms then return nil end
    if self.tracks[kind]~=nil then return self.tracks[kind] or nil end
    local kit=RS:FindFirstChild("ZO_WeaponAssets")
    local prefix=self.instance:GetAttribute("ZO_AnimationPrefix") or self.instance:GetAttribute("AnimationPrefix")
        or self:getConfigValue("AnimationType",self.settings.AnimationPrefix)
    prefix=if typeof(prefix)=="string" and #prefix>0 then prefix else self.settings.AnimationPrefix
    local function normalized(name) return string.lower((string.gsub(name,"[%s_]", ""))) end
    local wanted,fallback=normalized(prefix..kind),normalized("Rifle"..kind)
    local animation=nil
    local folders={}
    local localAnimations=self.instance:FindFirstChild("Animations")
    local globalAnimations=kit and kit:FindFirstChild("Animations")
    if localAnimations then table.insert(folders,localAnimations) end
    if globalAnimations then table.insert(folders,globalAnimations) end
    for _,animations in folders do
        for _,candidate in animations:GetDescendants() do
            if candidate:IsA("Animation") then
                local name=normalized(candidate.Name)
                if name==wanted then animation=candidate;break end
                if not animation and name==fallback then animation=candidate end
            end
        end
        if animation then break end
    end
    -- Missing global animations can be imported after the Tool; retry on the
    -- next pose transition instead of permanently caching an absent asset.
    if not animation then return nil end
    local ok,track=pcall(function() return self.arms.animator:LoadAnimation(animation) end)
    if not ok then
        self.tracks[kind]=false
        warn("[K17] First-person animation unavailable: "..self.id.."/"..kind)
        return nil
    end
    track.Looped=kind~="Reload"
    track.Priority=if kind=="Reload" then Enum.AnimationPriority.Action2 else Enum.AnimationPriority.Action
    self.tracks[kind]=track
    if kind=="Reload" then
        table.insert(self.connections,track:GetPropertyChangedSignal("Length"):Connect(function()
            if self.reloading and self.reloadDeadline and track.Length>0 then
                local remaining=math.max(.1,self.reloadDeadline-os.clock())
                track:AdjustSpeed(math.clamp(track.Length/remaining,.2,5))
            end
        end))
    end
    return track
end

function Presentation.new(template,parent,id,character)
    local instance=template:Clone()
    instance.Name="ZO_ViewWeapon_"..id
    local handle=instance:FindFirstChild("Handle")
    local model=instance:FindFirstChildOfClass("Model")
    local attachment=model and model:FindFirstChild("HandleAttachment",true)
    if not handle or not handle:IsA("BasePart") or not model or not model.PrimaryPart
        or not attachment or not attachment:IsA("Attachment") then
        instance:Destroy();return nil,"MissingGrip"
    end
    local originalPrimary=model.PrimaryPart.CFrame
    local handleOffset=originalPrimary:ToObjectSpace(attachment.WorldCFrame)
    local primaryToHandle=handleOffset:Inverse()
    -- Original BaseWeapon handle weld, shared by every imported template.
    local weld=handle:FindFirstChild("HandleWeld")
    if weld then weld:Destroy() end
    weld=Instance.new("Weld");weld.Name="HandleWeld";weld.Part0=handle;weld.Part1=model.PrimaryPart
    weld.C0=CFrame.identity;weld.C1=handleOffset;weld.Parent=handle
    local self=bind(instance,id)
    self.handle=handle;self.visible=false;self.visualParts={};self.tracks={};self.partOffsets={};self.motors={}
    -- Derive sight placement from the imported grip, before a weld or camera
    -- update has moved anything. Reading handle.CFrame here uses its editor pose.
    if self.tipAttach and self.tipAttach:IsA("Attachment") then
        self.tipOffset=primaryToHandle*originalPrimary:ToObjectSpace(self.tipAttach.WorldCFrame)
    end
    local sight=instance:FindFirstChild("AimDownSightsAttachment",true) or instance:FindFirstChild("SightAttachment",true)
    if sight and sight:IsA("Attachment") then
        self.sightOffset=primaryToHandle*originalPrimary:ToObjectSpace(sight.WorldCFrame)
    elseif self.tipOffset then self.sightOffset=self.tipOffset*self.settings.SightOffset end
    self.arms,self.armsStatus=copyArms(character,parent,false)
    local rigidNeighbors={}
    for _,part in instance:GetDescendants() do
        if part:IsA("LuaSourceContainer") then part:Destroy()
        elseif part:IsA("BasePart") then
            self.partOffsets[part]=if part==handle then CFrame.identity else primaryToHandle*originalPrimary:ToObjectSpace(part.CFrame)
            part.Anchored=true
            part.CanCollide=false;part.CanQuery=false;part.CanTouch=false;part.Massless=true;part.CastShadow=false
            part.LocalTransparencyModifier=1;table.insert(self.visualParts,part)
        elseif part:IsA("Motor6D") and part.Part0 and part.Part1 then
            table.insert(self.motors,{joint=part})
        elseif (part:IsA("Weld") or part:IsA("WeldConstraint")) and part.Part0 and part.Part1 then
            rigidNeighbors[part.Part0]=rigidNeighbors[part.Part0] or {}
            rigidNeighbors[part.Part1]=rigidNeighbors[part.Part1] or {}
            table.insert(rigidNeighbors[part.Part0],part.Part1)
            table.insert(rigidNeighbors[part.Part1],part.Part0)
        end
    end
    for _,entry in self.motors do
        local motor=entry.joint
        local group,visited={motor.Part1},{[motor.Part0]=true,[motor.Part1]=true}
        local cursor=1
        while cursor<=#group do
            for _,part in rigidNeighbors[group[cursor]] or {} do
                if not visited[part] and self.partOffsets[part] then visited[part]=true;table.insert(group,part) end
            end
            cursor+=1
        end
        entry.parts=group
    end
    if self.arms then
        local grip=Instance.new("Motor6D");grip.Name="RightGrip"
        grip.Part0=self.arms.hand;grip.Part1=handle
        local handGrip=self.arms.hand:FindFirstChild("RightGripAttachment")
        grip.C0=if handGrip and handGrip:IsA("Attachment") then handGrip.CFrame else CFrame.identity
        grip.C1=instance.Grip;grip.Parent=self.arms.hand;self.handGrip=grip
        for _,part in self.arms.parts do table.insert(self.visualParts,part) end
    end
    for part,offset in self.partOffsets do part.CFrame=CFrame.new(0,-10000,0)*offset end
    instance.Parent=parent
    return self,self.armsStatus
end

function Presentation:aimPose()
    if not self.sightOffset then return self.settings.HipPose end
    return CFrame.new(0,-.02,-self.settings.EyeRelief)*self.sightOffset:Inverse()
end

function Presentation:update(cameraCFrame,pose,visible,aimAlpha)
    if self.destroyed then return end
    local target=cameraCFrame*pose*self.settings.HipPose:Lerp(self:aimPose(),aimAlpha or 0)
    if self.arms then
        local grip=self.handGrip
        placeArms(self.arms,self.arms.root.CFrame)
        local relative=self.arms.root.CFrame:ToObjectSpace(self.arms.hand.CFrame*grip.C0*grip.Transform*grip.C1:Inverse())
        placeArms(self.arms,target*relative:Inverse())
    end
    for part,offset in self.partOffsets do part.CFrame=target*offset end
    -- Preserve the kit's bolt motor animation while keeping every imported mesh
    -- rigidly attached to this frame's camera position.
    for _,entry in self.motors do
        local motor=entry.joint
        if motor.Part0 and motor.Part1 then
            local desired=motor.Part0.CFrame*motor.C0*motor.Transform*motor.C1:Inverse()
            local delta=desired*motor.Part1.CFrame:Inverse()
            for _,part in entry.parts do part.CFrame=delta*part.CFrame end
        end
    end
    if self.visible~=visible then
        self.visible=visible
        for _,part in self.visualParts do part.LocalTransparencyModifier=if visible then 0 else 1 end
        if visible then self:tryPlaySound("Equip") else self:stop() end
    end
    if self.arms and visible and not self.reloading then
        local aim=(aimAlpha or 0)>.5
        local poseKind=if aim then "AimDownSights" else "Aim"
        local retryAnimations=self.tracks[poseKind]==nil and os.clock()>=(self.nextAnimationRetry or 0)
        if self.aimAnimation~=aim or not self.idleStarted or retryAnimations then
            self.aimAnimation=aim;self.idleStarted=true
            self.nextAnimationRetry=os.clock()+.5
            local hip,ads=self:getTrack("Aim"),self:getTrack("AimDownSights")
            if hip then if aim and ads then hip:Stop(.12) elseif not hip.IsPlaying then hip:Play(.12) end end
            if ads then if aim then ads:Play(.12) else ads:Stop(.12) end end
        end
    end
end

function Presentation.newArms(character,parent)
    local arms,status=copyArms(character,parent,true)
    if not arms then return nil,status end
    return {arms=arms,visible=false},status
end
function Presentation.updateArms(self,camera,visible,swing)
    placeArms(self.arms,camera*CFrame.new(0,.1+swing*.15,.2-swing*.45)*self.arms.headOffset:Inverse())
    if self.visible~=visible then
        self.visible=visible
        for _,part in self.arms.parts do part.LocalTransparencyModifier=if visible then 0 else 1 end
    end
end
function Presentation.destroyArms(self) self.arms.model:Destroy() end

function Presentation.observeWorld(tool)
    local self=worldPresentations[tool]
    if self then return self end
    self=bind(tool);worldPresentations[tool]=self
    local function reload()
        self:setReloading(tool:GetAttribute("ZO_Reloading")==true,
            math.max(0,(tool:GetAttribute("ZO_ReloadEndsAt") or 0)-workspace:GetServerTimeNow()))
    end
    table.insert(self.connections,tool:GetAttributeChangedSignal("ZO_Reloading"):Connect(reload))
    table.insert(self.connections,tool:GetAttributeChangedSignal("ZO_ReloadEndsAt"):Connect(reload))
    table.insert(self.connections,tool.AncestryChanged:Connect(function()
        if not tool:IsDescendantOf(workspace) then self:stop() end
    end))
    tool.Destroying:Once(function()
        self:stop();self.destroyed=true
        for _,connection in self.connections do connection:Disconnect() end
        worldPresentations[tool]=nil
    end)
    reload();return self
end
function Presentation.playWorldShot(tool) Presentation.observeWorld(tool):fire() end

function Presentation.playDistantShot(template,origin,id)
    local part=Instance.new("Part");part.Name="ZO_ShotAudio"
    part.Size=Vector3.one*.05;part.Transparency=1;part.Anchored=true
    part.CanCollide=false;part.CanQuery=false;part.CanTouch=false;part.CastShadow=false;part.Position=origin
    local sound=findSound(template,"Fired")
    if not sound then part:Destroy();return false end
    sound=sound:Clone();sound.Volume*=PresentationConfig.get(id).FireVolume
    sound.PlaybackSpeed=math.max(.05,sound.PlaybackSpeed+localRandom:NextNumber(-.05,.05))
    sound.RollOffMinDistance=8;sound.RollOffMaxDistance=PresentationConfig.get(id).SoundDistance
    sound.Parent=part;part.Parent=workspace;sound:Play()
    Debris:AddItem(part,math.max(4,sound.TimeLength/sound.PlaybackSpeed+.25))
    return true
end

function Presentation.impact(position,normal)
    local kit=RS:FindFirstChild("ZO_WeaponAssets")
    local effects=kit and kit:FindFirstChild("Effects")
    local template=effects and effects:FindFirstChild("HitEffect",true)
    if not template or not template:IsA("Attachment") or normal.Magnitude<.001 then return end
    normal=normal.Unit
    local part=Instance.new("Part");part.Name="ZO_Impact"
    part.Size=Vector3.one*.05;part.Transparency=1;part.Anchored=true
    part.CanCollide=false;part.CanQuery=false;part.CanTouch=false;part.CastShadow=false
    part.CFrame=CFrame.lookAt(position+normal*.02,position+normal,
        if math.abs(normal.Y)>.98 then Vector3.xAxis else Vector3.yAxis)
    local effect=template:Clone();effect.CFrame=CFrame.identity;effect.Parent=part;part.Parent=workspace
    for _,item in effect:GetDescendants() do
        if item:IsA("ParticleEmitter") then
            item.Enabled=false
            local count=item:GetAttribute("EmitCount")
            item:Emit(if typeof(count)=="number" then math.clamp(math.floor(count),1,100) else 5)
        elseif item:IsA("Sound") then item:Play() end
    end
    Debris:AddItem(part,3)
end

function Presentation:destroy()
    if self.destroyed then return end
    self:stop();self.destroyed=true
    for _,track in self.tracks or {} do if track then track:Destroy() end end
    if self.arms then self.arms.model:Destroy() end
    for _,connection in self.connections do connection:Disconnect() end
    self.instance:Destroy()
end

return Presentation
