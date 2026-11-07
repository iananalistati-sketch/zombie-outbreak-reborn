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
local WeaponAimPose=require(script.Parent.WeaponAimPose)
local ViewRig=require(script.Parent.ViewRig)
local Handling=require(script.Parent.WeaponHandling)
local ImpactProfiles=require(script.Parent.ImpactProfiles)
local impactBudget=ImpactProfiles.budget(24)
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
    local self=setmetatable({instance=instance,sounds={},configValues={},flashSequence=0,shotSequence=0,destroyed=false,fireVoices={}},Presentation)
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
    if self.tipAttach then
        self.muzzleLight=Instance.new("PointLight");self.muzzleLight.Name="ZO_MuzzleLight"
        self.muzzleLight.Brightness=2.5;self.muzzleLight.Range=8;self.muzzleLight.Shadows=false
        self.muzzleLight.Color=Color3.fromRGB(255,207,142);self.muzzleLight.Enabled=false;self.muzzleLight.Parent=self.tipAttach
    end
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
    self.lastFireSound=self:tryPlaySound("Fired",self:getConfigValue("FiredPlaybackSpeedRange",.1))
    if self.lastFireSound then
        table.insert(self.fireVoices,self.lastFireSound)
        if #self.fireVoices>6 then local old=table.remove(self.fireVoices,1);if old.Parent then old:Stop();old:Destroy() end end
    end
    self.shotSequence+=1
    self.lastShotAt=os.clock()
    local sequence=self.shotSequence
    self.flashSequence+=1
    local flashSequence=self.flashSequence
    if self.muzzleLight then
        self.muzzleLight.Enabled=true
        task.delay(.035,function()if not self.destroyed and self.flashSequence==flashSequence then self.muzzleLight.Enabled=false end end)
    end
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
        task.delay(self:getConfigValue("MuzzleFlashTime",.03),function()
            if not self.destroyed and flashSequence==self.flashSequence then self.muzzleFlashBeam.Enabled=false end
        end)
    end
end

local function alignReload(self,remaining)
    if not remaining or remaining<=0 then return end
    self.reloadDeadline=os.clock()+remaining
    if self.reloadSound and self.reloadSound.TimeLength>0 then
        local duration=self.reloadDuration or remaining
        self.reloadSound.PlaybackSpeed=math.clamp(self.reloadSound.TimeLength/duration,.5,2)
        self.reloadSound.TimePosition=math.max(0,self.reloadSound.TimeLength-remaining*self.reloadSound.PlaybackSpeed)
    end
    local track=self.tracks and self.tracks.Reload
    if track and track.Length>0 then track:AdjustSpeed(math.clamp(track.Length/remaining,.2,5)) end
end

function Presentation:setReloading(reloading,remaining,duration)
    if type(duration)=="number" and duration>0 then self.reloadDuration=duration end
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
                    alignReload(self,math.max(0,self.reloadDeadline-os.clock()))
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
    for _,sound in self.fireVoices do if sound.Parent then sound:Stop();sound:Destroy() end end
    table.clear(self.fireVoices);self.lastFireSound=nil
    if self.boltTween then self.boltTween:Cancel() end
    if self.muzzleFlashBeam then self.muzzleFlashBeam.Enabled=false end
    if self.muzzleLight then self.muzzleLight.Enabled=false end
    if self.boltMotor and self.boltMotorStart then self.boltMotor.C0=self.boltMotorStart.CFrame end
    if self.tracks then for _,track in self.tracks do if track then track:Stop(.1) end end end
    self.idleStarted=false
end

local copyArms=ViewRig.copy
local placeArms=ViewRig.place

function Presentation:getTrack(kind)
    if not self.arms or not self.arms.animator then return nil end
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
    track.Looped=false -- Aim/ADS are held pitch poses; Reload plays once.
    track.Priority=if kind=="Reload" then Enum.AnimationPriority.Action2 else Enum.AnimationPriority.Action
    self.tracks[kind]=track
    if kind=="Reload" then
        table.insert(self.connections,track:GetPropertyChangedSignal("Length"):Connect(function()
            if self.reloading and self.reloadDeadline and track.Length>0 then
                local remaining=math.max(.1,self.reloadDeadline-os.clock())
                track:AdjustSpeed(math.clamp(track.Length/remaining,.2,5))
            end
        end))
    else
        table.insert(self.connections,WeaponAimPose.bind(track))
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
        grip.C0=self.arms.gripOffset
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
    local progress=if self.reloading and self.reloadDeadline then 1-math.max(0,self.reloadDeadline-os.clock())/(self.reloadDuration or 2.4) else 0
    local handling=Handling.reload(self.id,progress)
    for part in self.partOffsets do
        if part.Name=="Magazine" and self.reloading then
            part.CFrame*=CFrame.new(0,-handling.Magazine,0)
        elseif part.Name=="Pump" then
            local pump=if self.reloading then handling.Pump else Handling.pump(os.clock()-(self.lastShotAt or -math.huge))
            -- Imported pump mesh has reversed local Z. Rack toward the grip's
            -- rear (+Z), independent of the mesh's authored orientation.
            part.CFrame=target*CFrame.new(0,0,pump)*target:Inverse()*part.CFrame
        end
    end
    if self.visible~=visible then
        self.visible=visible
        for _,part in self.visualParts do part.LocalTransparencyModifier=if visible then 0 else 1 end
        if visible then self:tryPlaySound("Equip") else self:stop() end
    end
    for part in self.partOffsets do
        if part.Name=="Magazine" then part.LocalTransparencyModifier=if not visible or (self.reloading and handling.HideMagazine) then 1 else 0 end
    end
    if self.arms and self.arms.animator and visible and not self.reloading then
        local aim=(aimAlpha or 0)>.5
        local poseKind=if aim then "AimDownSights" else "Aim"
        local retryAnimations=self.tracks[poseKind]==nil and os.clock()>=(self.nextAnimationRetry or 0)
        if self.aimAnimation~=aim or not self.idleStarted or retryAnimations then
            self.aimAnimation=aim;self.idleStarted=true
            self.nextAnimationRetry=os.clock()+.5
            local hip,ads=self:getTrack("Aim"),self:getTrack("AimDownSights")
            if hip then if aim and ads then hip:Stop(.12) elseif not hip.IsPlaying then WeaponAimPose.hold(hip,.12) end end
            if ads then if aim then WeaponAimPose.hold(ads,.12) else ads:Stop(.12) end end
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
            math.max(0,(tool:GetAttribute("ZO_ReloadEndsAt") or 0)-workspace:GetServerTimeNow()),tool:GetAttribute("ZO_ReloadDuration"))
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

function Presentation.impact(position,normal,material)
    local kit=RS:FindFirstChild("ZO_WeaponAssets")
    local effects=kit and kit:FindFirstChild("Effects")
    local template=effects and effects:FindFirstChild("HitEffect",true)
    if not template or not template:IsA("Attachment") or normal.Magnitude<.001 then return end
    if not impactBudget:admit(os.clock()) then return end
    local profile=ImpactProfiles.get(material)
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
            item.Color=ColorSequence.new(Color3.fromRGB(table.unpack(profile.Color)))
            item.Lifetime=NumberRange.new(profile.Life*.7,profile.Life);item.Speed=NumberRange.new(profile.Speed*.5,profile.Speed)
            item.Size=NumberSequence.new(profile.Size);item.LightEmission=profile.Glow
            item.EmissionDirection=Enum.NormalId.Front;item.SpreadAngle=Vector2.new(45,45)
            item:Emit(profile.Count)
        elseif item:IsA("Sound") then item:Play() end
    end
    Debris:AddItem(part,profile.Life+.2)
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
