--!nonstrict
-- Roblox Weapons Kit AR presentation, adapted from the shipped BaseWeapon and
-- BulletWeapon modules. See third_party/roblox-weapon-kit for original sources
-- and Roblox Limited Use License. This module has no damage, input or hit RPCs.
-- Reused: handle weld (BaseWeapon lines 135-152), sound cloning (387-411),
-- bolt tween (BulletWeapon 141-158), shot sound/bolt (165-192), muzzle (347-361).
-- Integration glue: camera placement, visibility, cancellation and FX dispatch.
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local localRandom=Random.new()
local Presentation={}
Presentation.__index=Presentation
local worldPresentations=setmetatable({},{__mode="k"})

local function bind(instance)
    local self=setmetatable({instance=instance,sounds={},configValues={},flashSequence=0,shotSequence=0,destroyed=false},Presentation)
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
        soundTemplate=self.instance:FindFirstChild(soundName,true)
        self.sounds[soundName]=soundTemplate
    end
    if not soundTemplate or not soundTemplate:IsA("Sound") then return end
    local sound=soundTemplate:Clone()
    sound.PlaybackSpeed=sound.PlaybackSpeed+localRandom:NextNumber(-playbackSpeedRange*.5,playbackSpeedRange*.5)
    sound.Parent=soundTemplate.Parent
    sound:Play()
    Debris:AddItem(sound,math.max(3,sound.TimeLength/math.max(.01,sound.PlaybackSpeed)+.25))
    return sound
end

-- BulletWeapon:animateBoltAction, using the imported motor and target attachments.
function Presentation:animateBoltAction(isOpen)
    if self.destroyed or not self.boltMotor or not self.boltMotorStart or not self.boltMotorTarget then return end
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
            if not self.destroyed and sequence==self.shotSequence then self:animateBoltAction(false) end
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

function Presentation:setReloading(reloading,remaining)
    if reloading==self.reloading then return end
    self.reloading=reloading
    if self.reloadSound then self.reloadSound:Stop();self.reloadSound:Destroy();self.reloadSound=nil end
    if reloading and not self.destroyed then
        self.reloadSound=self:tryPlaySound("Reload")
        if self.reloadSound and self.reloadSound.TimeLength>0 and remaining then
            self.reloadSound.TimePosition=math.max(0,self.reloadSound.TimeLength-remaining)
        end
    end
end

function Presentation:stop()
    self.shotSequence+=1;self.flashSequence+=1
    self:setReloading(false)
    if self.lastFireSound then self.lastFireSound:Stop() end
    if self.boltTween then self.boltTween:Cancel() end
    if self.muzzleFlashBeam then self.muzzleFlashBeam.Enabled=false end
    if self.boltMotor and self.boltMotorStart then self.boltMotor.C0=self.boltMotorStart.CFrame end
end

function Presentation.new(template,parent)
    local instance=template:Clone()
    instance.Name="ZO_LocalReusedRifle"
    local handle=instance:FindFirstChild("Handle")
    local model=instance:FindFirstChildOfClass("Model")
    local handleAttachment=model and model:FindFirstChild("HandleAttachment",true)
    if not handle or not handle:IsA("BasePart") or not model or not model.PrimaryPart or not handleAttachment then
        instance:Destroy();return nil
    end
    -- BaseWeapon's handle weld aligns the actual kit model to its actual grip.
    local handleOffset=model.PrimaryPart.CFrame:ToObjectSpace(handleAttachment.WorldCFrame)
    local weld=Instance.new("Weld")
    weld.Name="HandleWeld";weld.Part0=handle;weld.Part1=model.PrimaryPart
    weld.C0=CFrame.new();weld.C1=handleOffset;weld.Parent=handle
    local self=bind(instance)
    self.handle=handle;self.visualParts={};self.visible=false
    for _,descendant in instance:GetDescendants() do
        if descendant:IsA("BasePart") then
            descendant.Anchored=descendant==handle
            descendant.CanCollide=false;descendant.CanQuery=false;descendant.CanTouch=false
            descendant.Massless=true;descendant.CastShadow=false
            descendant.LocalTransparencyModifier=1
            table.insert(self.visualParts,descendant)
        end
    end
    handle.CFrame=CFrame.new(0,-10000,0)
    instance.Parent=parent
    return self
end

function Presentation:update(cameraCFrame,pose,visible)
    if self.destroyed then return end
    self.handle.CFrame=cameraCFrame*pose*CFrame.new(.65,-.8,-1.2)
    if self.visible~=visible then
        self.visible=visible
        for _,part in self.visualParts do part.LocalTransparencyModifier=if visible then 0 else 1 end
        if not visible then self:stop() end
    end
end

function Presentation.playWorldShot(tool)
    local self=worldPresentations[tool]
    if not self then
        self=bind(tool);worldPresentations[tool]=self
        tool.Destroying:Once(function()
            self:stop();self.destroyed=true;worldPresentations[tool]=nil
        end)
    end
    self:fire()
end

function Presentation:destroy()
    if self.destroyed then return end
    self:stop();self.destroyed=true;self.instance:Destroy()
end

return Presentation
