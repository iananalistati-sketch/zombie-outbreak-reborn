-- Exercise movement policy with repeated fire, mixed directions and heavy/light loads.
local Physics=require("../../src/maps/k17/barricades/Physics")
local Config=require("../../src/maps/k17/barricades/Config")
local checks=0
local function expect(ok: boolean,label: string)
    assert(ok,label);checks+=1
end
local function near(a: number,b: number): boolean return math.abs(a-b)<1e-6 end
local force,cap=Config.Physics.BulletImpulse,Config.Physics.MaxSpeed
expect(Config.Physics.BulletImpulse>Config.Physics.MeleeImpulse,"rifle impulse exceeds zombie melee impulse")
for name,kind in Config.Kinds do
    local x,z=Physics.impulse(kind.Mass,0,0,1,0,force,cap)
    local cappedImpulse=math.min(force,kind.Mass*cap)
    expect(near(x,cappedImpulse) and near(z,0),name..": first rifle impulse respects the speed cap")
    local melee=Physics.impulse(kind.Mass,0,0,1,0,Config.Physics.MeleeImpulse,cap)
    expect(x>melee,name..": one rifle hit moves the same resting prop more than one zombie hit")
    local vx,vz=0,0
    for i=1,60 do
        local dx,dz=Physics.impulse(kind.Mass,vx,vz,if i<30 then 1 else -1,.3,force,cap)
        vx+=dx/kind.Mass;vz+=dz/kind.Mass
        expect(vx*vx+vz*vz<=cap*cap+.000001,name..": sustained fire remains within the speed cap")
    end
    local ix,iz=Physics.impulse(kind.Mass,0,0,0,0,force,cap)
    expect(ix==0 and iz==0,name..": vertical-only shot has no horizontal impulse")
end
local x=Physics.impulse(24,0,0,1,0,force,cap)
local heavy=Physics.impulse(55,0,0,1,0,force,cap)
expect(x/24>heavy/55,"lighter crate gains more velocity than heavy cabinet")
local x,z=Physics.impulse(24,cap,0,1,0,force,cap)
expect(near(x,0) and near(z,0),"shot at the forward speed cap adds no excess impulse")
local x,z=Physics.impulse(24,0,0,3,4,force,cap)
local diagonal=math.min(force,24*cap)
expect(near(x,diagonal*.6) and near(z,diagonal*.8),"diagonal shot preserves its direction when capped")
local x,z=Physics.impulse(math.huge,0,0,1,0,force,cap)
expect(x==0 and z==0,"nonfinite assembly mass is rejected")
for _,args in {
    {0,0,0,1,0,force,cap}, {-1,0,0,1,0,force,cap},
    {0/0,0,0,1,0,force,cap}, {24,0/0,0,1,0,force,cap},
    {24,0,math.huge,1,0,force,cap}, {24,0,0,math.huge,0,force,cap},
    {24,0,0,1,0,-1,cap}, {24,0,0,1,0,force,0},
} do
    local ix,iz=Physics.impulse(table.unpack(args))
    expect(ix==0 and iz==0,"invalid physics input is rejected without NaN/inf impulse")
end
print("PASS prop physics policy: "..checks.." assertions; engine contacts/friction not executed")
