-- Executes the actual MIT-derived horizontal solver, without Roblox physics.
local Movement=assert(loadstring(SOURCE_MOVEMENT_SOURCE))()
local checks=0
local function check(ok,label) assert(ok,label);checks+=1 end
local function near(a,b,tolerance) return math.abs(a-b)<(tolerance or 1e-6) end
local function length(x,z) return math.sqrt(x*x+z*z) end
local function finite(value) return value==value and math.abs(value)<math.huge end
local function simulate(x,z,wx,wz,speed,grounded,seconds,fps)
    for _=1,math.floor(seconds*fps+.5) do x,z=Movement.step(x,z,wx,wz,speed,grounded,1/fps) end
    return x,z
end

do
    local x,z=Movement.step(0,0,1,0,16,true,1/120)
    check(near(x,4/3) and z==0,"ground acceleration starts gradually at the adapted Source rate")
    x,z=simulate(0,0,1,0,16,true,.5,120)
    check(near(x,16) and z==0,"holding forward reaches the server-composed speed")
    x,z=simulate(x,z,1,0,8,true,.5,120)
    check(near(x,8) and z==0,"lower server stance or containment speed becomes the new target")
    local dx,dz=simulate(0,0,1,1,16,true,.5,120)
    check(near(length(dx,dz),16) and near(dx,dz),"diagonal digital input does not multiply ground speed")
    local ax,az=simulate(0,0,.5,0,16,true,.5,120)
    check(near(ax,8) and az==0,"analog input retains its proportional speed")
end

do
    local coast=Movement.step(16,0,0,0,16,true,1/120)
    local counter=Movement.step(16,0,-1,0,16,true,1/120)
    check(near(coast,16*(1-7/120)),"releasing input applies the upstream ground-friction drop")
    check(counter>=0 and counter<coast,"opposite input brakes faster than simply releasing input")
    local x,z=simulate(16,0,0,0,16,true,.5,120)
    check(x==0 and z==0,"stop-speed friction reaches rest without reversing direction")
    x,z=simulate(16,0,-1,0,16,true,.5,120)
    check(near(x,-16) and z==0,"continued counter input can accelerate in the new direction")
end

do
    local x,z=simulate(16,0,0,0,16,false,1,120)
    check(x==16 and z==0,"airborne release preserves horizontal momentum")
    x,z=simulate(16,0,0,1,16,false,1,120)
    check(x==16 and near(z,3),"air acceleration caps projection along the new wish direction")
    x,z=simulate(16,0,1,0,16,false,1,120)
    check(x==16 and z==0,"existing air speed above the projection cap is preserved")
    x,z=Movement.step(100,100,1,1,100,false,1/60)
    check(near(length(x,z),32),"the horizontal safety cap bounds large observed impulses")
    local bounded=true
    for frame=1,1200 do
        local angle=frame*.13
        x,z=Movement.step(x,z,math.cos(angle),math.sin(angle),32,false,1/120)
        bounded=bounded and finite(x) and finite(z) and length(x,z)<=32.000001
    end
    check(bounded,"repeated air strafing stays finite and bounded over 1200 changing inputs")
end

do
    for _,fps in {30,60,120} do
        local x,z=simulate(0,0,1,0,16,true,.1,fps)
        local referenceX,referenceZ=simulate(0,0,1,0,16,true,.1,120)
        check(near(x,referenceX) and near(z,referenceZ),"substeps keep initial acceleration consistent at normal frame rates")
        x,z=simulate(16,0,0,0,16,true,.3,fps)
        referenceX,referenceZ=simulate(16,0,0,0,16,true,.3,120)
        check(near(x,referenceX) and near(z,referenceZ),"substeps keep coasting consistent at normal frame rates")
    end
    local x,z=Movement.step(0,0,1,0,16,true,10)
    local bx,bz=Movement.step(0,0,1,0,16,true,.05)
    check(near(x,bx) and near(z,bz),"a long simulation stall cannot produce an unbounded acceleration step")
end

do
    for _,bad in {math.huge,-math.huge,0/0} do
        for index=1,7 do
            if index~=6 then
                local args={8,2,1,0,16,true,1/60};args[index]=bad
                local x,z=Movement.step(table.unpack(args))
                check(finite(x) and finite(z),"non-finite numeric inputs cannot poison horizontal velocity")
            end
        end
    end
    for _,dt in {0,-1} do
        local x,z=Movement.step(8,2,1,0,16,true,dt)
        check(x==8 and z==2,"a non-positive time delta leaves observed velocity unchanged")
    end
    local x,z=Movement.step(8,2,1,0,0,true,1/60)
    check(x==0 and z==0,"a disabled server movement speed cannot receive drive")
end

print(("PASS Source movement kernel: %d checks; actual source, no Roblox physics"):format(checks))
