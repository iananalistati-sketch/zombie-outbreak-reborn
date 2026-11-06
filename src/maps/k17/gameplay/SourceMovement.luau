--!strict
-- Port of Accelerate/ApplyFriction and air-cap logic from Olezen's modified
-- Fragsurf SurfController/SurfPhysics, MIT (c) 2019 Ole Ellefsen Farner.
-- Exact C# sources and license: third_party/tactical-fps-sources/.
-- Pure horizontal solver; Roblox retains gravity, jump, collision and rig.
local Movement={}
local function finite(value: any): boolean
    return type(value)=="number" and value==value and math.abs(value)<1e6
end
function Movement.step(vx: number,vz: number,wx: number,wz: number,speed: number,grounded: boolean,dt: number): (number,number)
    if not finite(vx) or not finite(vz) then vx=0;vz=0 end
    if not finite(wx) or not finite(wz) then wx=0;wz=0 end
    if not finite(speed) or speed<=0 then return 0,0 end
    speed=math.min(speed,32)
    if not finite(dt) or dt<=0 then return vx,vz end
    local magnitude=math.sqrt(wx*wx+wz*wz)
    local strength=math.min(magnitude,1)
    if magnitude>1e-6 then wx/=magnitude;wz/=magnitude else wx=0;wz=0 end
    local remaining=math.min(dt,.05)
    while remaining>1e-7 do
        local step=math.min(remaining,1/120);remaining-=step
        if grounded then
            local current=math.sqrt(vx*vx+vz*vz)
            if current>0 then
                local control=math.max(current,6)
                local nextSpeed=math.max(0,current-control*7*step)
                vx*=nextSpeed/current;vz*=nextSpeed/current
            end
        end
        local wishSpeed=speed*strength
        local currentSpeed=vx*wx+vz*wz
        local cappedWish=if grounded then wishSpeed else math.min(wishSpeed,3)
        local addSpeed=cappedWish-currentSpeed
        if addSpeed>0 then
            local acceleration=if grounded then (if currentSpeed<0 then 18 else 10) else 8
            local accelerationSpeed=math.min(acceleration*step*wishSpeed,addSpeed)
            vx+=accelerationSpeed*wx;vz+=accelerationSpeed*wz
        end
        local horizontal=math.sqrt(vx*vx+vz*vz)
        if horizontal>32 then vx*=32/horizontal;vz*=32/horizontal end
    end
    return vx,vz
end
return table.freeze(Movement)
