--!strict
-- Critical-damping branch adapted from Fraktality/spr LinearSpring.step,
-- as vendored (explicit MIT header) in Evostrike c_spr.lua at 221a3a2.
-- Copyright (c) 2023 Fractality. MIT notices and exact source in
-- third_party/tactical-fps-sources/spr/. No GPL engine code is used here.
local Spring={}
Spring.__index=Spring
local function finite(value: any): boolean
    return type(value)=="number" and value==value and math.abs(value)<1e6
end
function Spring.new(frequency: number)
    return setmetatable({frequency=math.clamp(frequency,1,30),position=0,velocity=0},Spring)
end
function Spring:reset()
    self.position=0;self.velocity=0
end
function Spring:kick(amount: number)
    if finite(amount) then self.position=math.clamp(self.position+amount,-50,50) end
end
function Spring:step(dt: number,goal: number): number
    if not finite(dt) or dt<=0 or not finite(goal) then return self.position end
    dt=math.min(dt,.1);goal=math.clamp(goal,-50,50)
    local f=self.frequency*2*math.pi
    local q=math.exp(-f*dt)
    local w=dt*q
    local c0=q+w*f
    local c2=q-w*f
    local c3=w*f*f
    local offset=self.position-goal
    self.position=offset*c0+self.velocity*w+goal
    self.velocity=self.velocity*c2-offset*c3
    if math.abs(self.position-goal)<1e-6 and math.abs(self.velocity)<1e-5 then
        self.position=goal;self.velocity=0
    end
    return self.position
end
return table.freeze(Spring)
