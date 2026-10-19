local Policy=require("../../src/maps/k17/gameplay/Containment")
local passed=0
local function check(ok,label) assert(ok,label);passed+=1 end
local function near(a,b) return math.abs(a-b)<1e-6 end
local x,y,z=Policy.velocity(0,0,19,0,0,-1,27.5,48,10)
check(near(z,-8.5) and x==0 and y==0,"body hit reverses the forward approach instead of adding speed toward the human")
local vx,vz=0,0
for i=1,80 do
    vx,_,vz=Policy.velocity(vx,0,vz,1,0,-1,27.5,48,10)
    check(vx*vx+vz*vz<=48*48+.00001,"coordinated continuous fire has a bounded cumulative velocity")
end
local ax,ay,az=Policy.velocity(0,-24,0,1,0,0,20,48,10)
check(ax==20 and ay==-24 and az==0,"horizontal hit does not cancel a falling zombie's gravity")
local _,up=Policy.velocity(0,3,0,0,1,0,60,48,10)
check(up==10,"upward volley cannot launch a zombie without a vertical cap")
local a,b,c=Policy.velocity(2,3,4,0,0,0,27.5,48,10)
check(a==2 and b==3 and c==4,"zero direction leaves a valid velocity intact")
for _,bad in {0/0,math.huge,-math.huge} do
    local x,y,z=Policy.velocity(1,2,3,bad,0,-1,20,48,10)
    check(x==1 and y==2 and z==3,"invalid direction cannot poison physics")
end
local x,y,z=Policy.velocity(0/0,math.huge,-math.huge,1,0,0,20,48,10)
check(x==20 and y==0 and z==0,"nonfinite incoming physical state is sanitized")
local expiry=Policy.tagUntil(0,10,.18)
check(near(expiry,10.18),"one hit gives a short recovery window")
check(near(Policy.walkSpeed(19,10,expiry,.55),10.45),"a tagged zombie temporarily loses forward speed")
check(Policy.walkSpeed(19,expiry,expiry,.55)==19,"the exact expiry restores normal movement")
expiry=Policy.tagUntil(expiry,10.1,.18)
check(near(expiry,10.28),"successive hits refresh from now instead of accumulating stun durations")
check(Policy.walkSpeed(19,10.29,expiry,.55)==19,"a pause in fire opens the approach again")
check(Policy.tagUntil(expiry,10.01,.18)==expiry,"older callbacks cannot shorten a newer tag")
check(Policy.walkSpeed(16,10,0,.55)==16,"an untagged human keeps their own movement base")
check(Policy.tagUntil(0,10,900)==11,"a malformed duration cannot create an unbounded freeze")
print(("PASS containment policy: %d assertions; Humanoid movement and replication require Studio"):format(passed))
