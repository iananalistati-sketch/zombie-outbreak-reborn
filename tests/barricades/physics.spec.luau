-- Exercise movement policy with repeated fire, mixed directions and heavy/light loads.
local Physics=require("../../src/maps/k17/barricades/Physics")
local Config=require("../../src/maps/k17/barricades/Config")
local checks=0
local function expect(ok: boolean)
    assert(ok);checks+=1
end
local function near(a: number,b: number): boolean return math.abs(a-b)<1e-6 end
local force,cap=Config.Physics.BulletImpulse,Config.Physics.MaxSpeed
for _,kind in Config.Kinds do
    local x,z=Physics.impulse(kind.Mass,0,0,1,0,force,cap)
    expect(near(x,force) and near(z,0))
    local vx,vz=0,0
    for i=1,60 do
        local dx,dz=Physics.impulse(kind.Mass,vx,vz,if i<30 then 1 else -1,.3,force,cap)
        vx+=dx/kind.Mass;vz+=dz/kind.Mass
        expect(vx*vx+vz*vz<=cap*cap+.000001)
    end
    local ix,iz=Physics.impulse(kind.Mass,0,0,0,0,force,cap)
    expect(ix==0 and iz==0)
end
local x=Physics.impulse(24,0,0,1,0,force,cap)
local heavy=Physics.impulse(55,0,0,1,0,force,cap)
expect(x/24>heavy/55)
local x,z=Physics.impulse(24,12,0,1,0,force,cap)
expect(near(x,0) and near(z,0))
local x,z=Physics.impulse(24,0,0,3,4,force,cap)
expect(near(x,force*.6) and near(z,force*.8))
local x,z=Physics.impulse(math.huge,0,0,1,0,force,cap)
expect(x==0 and z==0)
print("PASS prop physics policy: "..checks.." assertions; engine contacts/friction not executed")
