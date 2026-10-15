--!strict
-- Horizontal impulse with a speed cap; engine friction/contact still needs Studio.
local Physics={}
local function finite(value: number): boolean
    return value==value and math.abs(value)<math.huge
end
function Physics.impulse(mass: number,vx: number,vz: number,dx: number,dz: number,force: number,cap: number): (number,number)
    -- Reject invalid state instead of feeding NaN/infinity into a live assembly.
    if not finite(mass) or not finite(vx) or not finite(vz) or not finite(dx)
        or not finite(dz) or not finite(force) or not finite(cap) then return 0,0 end
    local length=math.sqrt(dx*dx+dz*dz)
    if length<.001 or mass<=0 or force<=0 or cap<=0 then return 0,0 end
    local x,z=vx+dx/length*force/mass,vz+dz/length*force/mass
    local speed=math.sqrt(x*x+z*z)
    if speed>cap then x*=cap/speed;z*=cap/speed end
    return (x-vx)*mass,(z-vz)*mass
end
return table.freeze(Physics)
