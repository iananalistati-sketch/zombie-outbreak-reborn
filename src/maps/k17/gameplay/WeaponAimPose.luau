--!strict
-- Adapted from Roblox Weapons Kit / Libraries / BulletWeapon:onRenderStepped
-- (pinned kit lines 960-974). Roblox Corporation, Roblox Limited Use License;
-- community fixes: Copyright (c) 2025 JustATortoise, MIT. See
-- third_party/roblox-weapon-kit/ for the original model and license texts.
-- RifleAim and RifleAimDownSights are pitch-indexed poses, not idle loops.
local WeaponAimPose={}
local MIN_ANGLE=-80
local MAX_ANGLE=80
-- Reuse the kit's pitch-to-timeline mapping at neutral pitch. The first-person
-- rig already follows the camera; its arms need the neutral relative pose.
local neutralTime=math.clamp(2*((0-MIN_ANGLE)/(MAX_ANGLE-MIN_ANGLE)),.001,1.97)

local function seek(track: AnimationTrack)
    if not track.IsPlaying then return end
    track:AdjustSpeed(0)
    -- Length is initially zero while Roblox loads the animation. bind() seeks
    -- once it arrives, provided this pose still belongs to an active track.
    if track.Length>0 then
        track.TimePosition=math.min(neutralTime,math.max(.001,track.Length-.001))
    end
end

function WeaponAimPose.hold(track: AnimationTrack,fadeTime: number?)
    track.Looped=false
    if not track.IsPlaying then track:Play(fadeTime or .12,1,0) end
    seek(track)
end

function WeaponAimPose.bind(track: AnimationTrack): RBXScriptConnection
    return track:GetPropertyChangedSignal("Length"):Connect(function()
        -- Loading after unequip/reload must never restart a stopped pose.
        seek(track)
    end)
end

return table.freeze(WeaponAimPose)
