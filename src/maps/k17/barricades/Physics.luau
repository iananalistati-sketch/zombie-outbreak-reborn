--!strict
-- Horizontal impulse with a speed cap; engine friction/contact still needs Studio.
local Physics={}
function Physics.impulse(mass: number,vx: number,vz: number,dx: number,dz: number,force: number,cap: number): (number,number)
    local length=math.sqrt(dx*dx+dz*dz)
    if length<.001 or mass<=0 or mass==math.huge then return 0,0 end
    local x,z=vx+dx/length*force/mass,vz+dz/length*force/mass
    local speed=math.sqrt(x*x+z*z)
    if speed>cap then x*=cap/speed;z*=cap/speed end
    return (x-vx)*mass,(z-vz)*mass
end
return table.freeze(Physics)
