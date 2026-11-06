--!strict
-- Adapted from voximity/extract Client/Weapons.lua's walking/fast bob blend and
-- mouse-sway interpolation, revision 45afa80c93eeb8f4b21a84bab8a4b14a30ff33cc.
-- Copyright (c) 2019 voximity, MIT; see third_party/extract-movement/.
-- This local viewmodel offset never changes the camera or a firing direction.
local Motion={}
Motion.__index=Motion
local Spring=require(script.Parent:WaitForChild("TacticalSpring"))

local function capped(value: number,low: number,high: number): number
    if type(value)~="number" or value~=value or math.abs(value)==math.huge then return 0 end
    return math.clamp(value,low,high)
end

function Motion.new()
    return setmetatable({phase=0,bob=CFrame.identity,sway=CFrame.identity,current=CFrame.identity,
        amplitude=Spring.new(7),mouseX=Spring.new(8),mouseY=Spring.new(8),punch=Spring.new(8)},Motion)
end

function Motion:reset()
    self.phase=0
    self.bob=CFrame.identity;self.sway=CFrame.identity;self.current=CFrame.identity
    self.amplitude:reset();self.mouseX:reset();self.mouseY:reset();self.punch:reset()
end
function Motion:kick(amount: number)
    self.punch:kick(math.clamp(amount,0,.45))
end

function Motion:update(dt: number,speed: number,aimAlpha: number,crouching: boolean,mouseX: number,mouseY: number): CFrame
    local step=capped(dt,0,.1)
    if step==0 then return self.current end
    local velocity=capped(speed,0,40)
    local aim=capped(aimAlpha,0,1)
    local strength=(1-.85*aim)*(if crouching==true then .55 else 1)
    local movement=self.amplitude:step(step,math.clamp(velocity/8,0,1)*strength)
    self.phase=(self.phase+step*velocity/16)%(math.pi*200)
    local t=self.phase

    -- Reuse Extract's sine frequencies and speed-band interpolation with
    -- deliberately smaller offsets. There is no idle breathing displacement.
    local walk=CFrame.new(math.sin(t*5)*.035,-math.cos(t*10)*.022,0)
        *CFrame.Angles(math.sin(t*5-.9)*math.rad(.6),0,math.sin(t*6.3)*math.rad(.2))
    local fast=CFrame.new(math.sin(t*9)*.045,-math.cos(t*18)*.028,0)
        *CFrame.Angles(math.sin(t*9-1.2)*math.rad(.8),math.sin(t*9-1.2)*math.rad(.3),math.sin(t*12.6)*math.rad(.3))
    local blend=math.clamp((velocity-16)/10,0,1)
    local bobTarget=CFrame.identity:Lerp(walk:Lerp(fast,blend),movement)
    self.bob=self.bob:Lerp(bobTarget,1-math.exp(-12*step))

    -- GetMouseDelta is per frame. Normalize to a 60 Hz input rate before
    -- applying the reused pitch/yaw sway; cap flicks and long-frame changes.
    local divisor=math.max(step,1/240)*60
    local dx=capped(capped(mouseX,-1000,1000)/divisor,-20,20)
    local dy=capped(capped(mouseY,-1000,1000)/divisor,-20,20)
    local sx=self.mouseX:step(step,dx*strength)
    local sy=self.mouseY:step(step,dy*strength)
    self.sway=CFrame.Angles(math.rad(sy*.075),math.rad(sx*.075),0)
    if movement==0 and dx==0 and dy==0 then
        -- Snap only imperceptible residuals, so standing still is neutral and
        -- switching tools cannot accumulate a persistent presentation offset.
        local _,bobAngle=self.bob:ToAxisAngle()
        if self.bob.Position.Magnitude<1e-5 and math.abs(bobAngle)<1e-5 then self.bob=CFrame.identity end
        local _,angle=self.sway:ToAxisAngle()
        if math.abs(angle)<1e-5 then self.sway=CFrame.identity end
    end
    local punch=self.punch:step(step,0)*(1-.6*aim)
    self.current=self.sway*self.bob*CFrame.new(0,0,punch)*CFrame.Angles(punch*.65,0,-punch*.25)
    return self.current
end

return table.freeze(Motion)
