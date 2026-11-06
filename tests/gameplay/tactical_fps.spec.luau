-- Pure numerical checks for the actual licensed adaptations; no API doubles.
local Spring=require("../../src/maps/k17/gameplay/TacticalSpring")
local Recoil=require("../../src/maps/k17/gameplay/TacticalRecoil")
local checks=0
local function check(value,label) assert(value,label);checks+=1 end
local function close(a,b) return math.abs(a-b)<1e-8 end

do
    local spring=Spring.new(7)
    spring:kick(.3)
    local t=1/60
    local f=7*2*math.pi
    check(close(spring:step(t,0),.3*(1+f*t)*math.exp(-f*t)),"kick follows the critical damping closed form")
    check(close(spring.velocity,-.3*f*f*t*math.exp(-f*t)),"velocity follows the analytic derivative")
    local previous=spring.position
    local stable=true
    for _=1,120 do
        local p=spring:step(1/60,0)
        stable=stable and p>=0 and p<=previous+1e-10
        previous=p
    end
    check(stable and spring.position==0 and spring.velocity==0,"critical recoil settles without overshoot or residual drift")
    spring:kick(.1);spring:kick(.2)
    check(close(spring.position,.3),"consecutive gun impulses combine before recovery")
    spring:reset()
    check(spring.position==0 and spring.velocity==0,"unequip reset removes position and velocity")
    local a,b=Spring.new(8),Spring.new(8)
    for _=1,6 do a:step(1/30,2) end
    for _=1,24 do b:step(1/120,2) end
    check(close(a.position,b.position) and close(a.velocity,b.velocity),"equal time gives equal spring response at 30 and 120 FPS")
    check(a.position>0 and a.position<2,"goal approach stays within the step target")
    local p,v=a.position,a.velocity
    a:step(0,3);a:step(-1,3);a:step(0/0,3);a:step(1/60,math.huge);a:kick(0/0)
    check(a.position==p and a.velocity==v,"invalid inputs do not poison an active spring")
    local c,d=Spring.new(8),Spring.new(8)
    c:kick(.4);d:kick(.4);c:step(1,0);d:step(.1,0)
    check(close(c.position,d.position),"long frame catch-up is bounded")
end

do
    local recoil=Recoil.new()
    for _,id in {"Rifle","SMG","Pistol","Shotgun"} do
        recoil:reset()
        local up,side=recoil:shot(id,1,.8,1)
        check(close(up,.8) and close(side,0),id.." begins a clean burst at the configured pitch")
        local left,right,bounded=false,false,true
        for i=2,30 do
            up,side=recoil:shot(id,1+i*.05,.8,1)
            left=left or side<0;right=right or side>0
            bounded=bounded and up>=.8 and up<=1.04 and math.abs(side)<=.4
        end
        check(left and right and bounded,id.." has bounded two-sided burst control")
        up,side=recoil:shot(id,10,.8,1)
        check(close(up,.8) and close(side,0),id.." burst resets after a pause")
        local hip,aim=Recoil.new(),Recoil.new()
        hip:shot(id,0,.8,1);aim:shot(id,0,.8,.5)
        local hp,hy=hip:shot(id,.05,.8,1)
        local ap,ay=aim:shot(id,.05,.8,.5)
        check(close(ap,hp*.5) and close(ay,hy*.5),id.." aiming scales both recoil axes")
    end
    recoil:shot("Rifle",10.05,.8,1)
    local up,side=recoil:shot("SMG",10.1,.5,1)
    check(close(up,.5) and close(side,0),"changing weapon starts its own burst")
    recoil:shot("SMG",10.15,.5,1);recoil:reset()
    up,side=recoil:shot("SMG",10.2,.5,1)
    check(close(up,.5) and close(side,0),"control cancellation explicitly clears the burst")
    up,side=recoil:shot("Unknown",11,100,1)
    check(up==4 and side==0,"fallback profile caps vertical recoil")
    local a,b=Recoil.new(),Recoil.new()
    local deterministic=true
    for i=1,60 do
        local ap,ay=a:shot("Rifle",i*.1,.65,1)
        local bp,by=b:shot("Rifle",i*.1,.65,1)
        deterministic=deterministic and ap==bp and ay==by
    end
    check(deterministic,"the same burst sequence is reproducible without random state")
end
print("PASS actual TacticalSpring/TacticalRecoil modules: "..checks.." numerical checks; no Roblox execution")
