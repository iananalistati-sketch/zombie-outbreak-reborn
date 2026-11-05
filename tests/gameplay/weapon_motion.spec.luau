-- Run the real module with small rigid-transform API doubles. No services,
-- camera, weapon controller or ballistic state are available to this module.
local checks=0
local function check(ok,label) assert(ok,label);checks+=1 end
local function quat(w,x,y,z) return {w,x,y,z} end
local function multiply(a,b)
    return quat(a[1]*b[1]-a[2]*b[2]-a[3]*b[3]-a[4]*b[4],
        a[1]*b[2]+a[2]*b[1]+a[3]*b[4]-a[4]*b[3],
        a[1]*b[3]-a[2]*b[4]+a[3]*b[1]+a[4]*b[2],
        a[1]*b[4]+a[2]*b[3]-a[3]*b[2]+a[4]*b[1])
end
local mt={}
local function frame(x,y,z,q)
    local p={X=x or 0,Y=y or 0,Z=z or 0}
    p.Magnitude=math.sqrt(p.X*p.X+p.Y*p.Y+p.Z*p.Z)
    return setmetatable({Position=p,q=q or quat(1,0,0,0)},mt)
end
mt.__index={}
function mt.__index:Lerp(other,alpha)
    local a,b=self.q,other.q
    local dot=0;for i=1,4 do dot+=a[i]*b[i] end
    local sign=if dot<0 then -1 else 1
    local q={};local length=0
    for i=1,4 do q[i]=a[i]+(b[i]*sign-a[i])*alpha;length+=q[i]*q[i] end
    length=math.sqrt(length)
    for i=1,4 do q[i]/=length end
    local p,r=self.Position,other.Position
    return frame(p.X+(r.X-p.X)*alpha,p.Y+(r.Y-p.Y)*alpha,p.Z+(r.Z-p.Z)*alpha,q)
end
function mt.__index:ToAxisAngle()
    return {},2*math.acos(math.clamp(math.abs(self.q[1]),0,1))
end
mt.__mul=function(a,b)
    local p=b.Position
    local rotated=multiply(multiply(a.q,quat(0,p.X,p.Y,p.Z)),quat(a.q[1],-a.q[2],-a.q[3],-a.q[4]))
    return frame(a.Position.X+rotated[2],a.Position.Y+rotated[3],a.Position.Z+rotated[4],multiply(a.q,b.q))
end
local CFrame={new=frame,identity=frame()}
function CFrame.Angles(x,y,z)
    return frame(0,0,0,multiply(multiply(quat(math.cos(x/2),math.sin(x/2),0,0),
        quat(math.cos(y/2),0,math.sin(y/2),0)),quat(math.cos(z/2),0,0,math.sin(z/2))))
end
local fn=assert(loadstring(WEAPON_MOTION_SOURCE))
setfenv(fn,setmetatable({CFrame=CFrame},{__index=getfenv()}))
local Motion=fn()
local function angle(value) local _,a=value:ToAxisAngle();return a end
local function neutral(value) return value.Position.Magnitude==0 and angle(value)==0 end
local function finite(value)
    for _,n in {value.Position.X,value.Position.Y,value.Position.Z,table.unpack(value.q)} do
        if n~=n or math.abs(n)==math.huge then return false end
    end
    return true
end
local function sample(aim,crouch)
    local motion=Motion.new()
    local energy=0
    for _=1,180 do
        local value=motion:update(1/60,16,aim,crouch,0,0)
        energy+=value.Position.Magnitude+angle(value)
    end
    return energy
end

do
    local motion=Motion.new()
    check(neutral(motion:update(1/60,0,0,false,0,0)),"idle starts exactly neutral")
    local peakPosition,peakAngle=0,0
    for _=1,600 do
        local value=motion:update(1/60,16,0,false,0,0)
        peakPosition=math.max(peakPosition,value.Position.Magnitude)
        peakAngle=math.max(peakAngle,angle(value))
    end
    check(peakPosition>.01 and peakPosition<.06,"movement produces a modest viewmodel bob")
    check(peakAngle>math.rad(.1) and peakAngle<math.rad(1),"walking rotation stays below one degree")
    local value
    for _=1,180 do value=motion:update(1/60,0,0,false,0,0) end
    check(neutral(value),"stopping settles to exact neutral instead of persistent drift")
    motion:update(1/60,30,0,false,10,-10);motion:reset()
    check(neutral(motion:update(0,30,0,false,10,-10)),"reset clears bob, phase and mouse sway")
    check(neutral(Motion.new():update(1/60,0,0,false,0,0)),"motion is isolated between weapon instances")
end

do
    local hip=sample(0,false)
    check(sample(1,false)<hip*.25,"aiming strongly reduces presentation movement")
    check(sample(0,true)<hip*.7,"crouching steadies the viewmodel")
    local motion=Motion.new()
    local left=motion:update(1/60,0,0,false,8,0)
    motion:reset()
    local right=motion:update(1/60,0,0,false,-8,0)
    check(left.q[3]*right.q[3]<0,"mouse sway changes direction with the mouse")
    for _=1,180 do right=motion:update(1/60,0,0,false,0,0) end
    check(neutral(right),"mouse movement settles after input stops")
end

do
    local function result(fps)
        local motion=Motion.new();local output
        for _=1,fps*2 do output=motion:update(1/fps,16,.3,false,240/fps,-120/fps) end
        return output
    end
    local slow,fast=result(30),result(120)
    local a,b=slow.Position,fast.Position
    local distance=math.sqrt((a.X-b.X)^2+(a.Y-b.Y)^2+(a.Z-b.Z)^2)
    check(distance<.008 and math.abs(angle(slow)-angle(fast))<math.rad(.3),
        "equal movement and mouse rates remain close at 30 and 120 FPS")
    local motion=Motion.new()
    local bad=motion:update(0/0,math.huge,0/0,true,math.huge,-math.huge)
    check(neutral(bad),"invalid frame time cannot advance or poison motion")
    bad=motion:update(1/60,0/0,math.huge,true,0/0,math.huge)
    check(neutral(bad),"non-finite speed and mouse inputs become neutral")
    local bounded=true
    for i=1,600 do
        local value=motion:update(if i%2==0 then .5 else 1/240,1e100,-1e100,false,1e100,-1e100)
        bounded=bounded and finite(value) and value.Position.Magnitude<.07 and angle(value)<math.rad(4)
    end
    check(bounded,"extreme finite inputs remain capped through long and short frames")
    local held=motion:update(0,16,0,false,1,1)
    check(motion:update(-1,0,0,false,0,0)==held,"nonpositive frame time preserves the prior transform")
end

print("PASS actual WeaponMotion module: "..checks.." checks; rigid-transform API doubles, no Roblox rendering")
