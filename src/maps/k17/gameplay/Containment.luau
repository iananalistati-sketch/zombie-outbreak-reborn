--!strict
-- Pure movement policy: the server applies the returned velocity change as impulse.
local Containment={}
local function finite(value: any): boolean
    return type(value)=="number" and value==value and math.abs(value)<1e6
end

function Containment.velocity(vx: number,vy: number,vz: number,dx: number,dy: number,dz: number,
    strength: number,horizontalCap: number,upwardCap: number): (number,number,number)
    vx=if finite(vx) then vx else 0
    vy=if finite(vy) then vy else 0
    vz=if finite(vz) then vz else 0
    if not finite(dx) or not finite(dy) or not finite(dz) or not finite(strength) or strength<=0
        or not finite(horizontalCap) or horizontalCap<=0 or not finite(upwardCap) or upwardCap<0 then
        return vx,vy,vz
    end
    local length=math.sqrt(dx*dx+dy*dy+dz*dz)
    if length<.001 then return vx,vy,vz end
    local x,y,z=vx+dx/length*strength,vy+dy/length*strength,vz+dz/length*strength
    local speed=math.sqrt(x*x+z*z)
    if speed>horizontalCap then x*=horizontalCap/speed;z*=horizontalCap/speed end
    -- Preserve downward motion/gravity; the cap only prevents launching upward.
    return x,math.min(y,upwardCap),z
end

function Containment.tagUntil(previous: number,now: number,seconds: number): number
    previous=if finite(previous) then previous else 0
    if not finite(now) or not finite(seconds) or seconds<=0 then return previous end
    return math.max(previous,now+math.min(seconds,1))
end

function Containment.walkSpeed(base: number,now: number,expiry: number,scale: number): number
    base=if finite(base) then math.clamp(base,0,200) else 0
    if not finite(now) or not finite(expiry) or now>=expiry then return base end
    return base*(if finite(scale) then math.clamp(scale,.1,1) else 1)
end

return table.freeze(Containment)
