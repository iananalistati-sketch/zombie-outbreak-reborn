-- Real composition module. Float property storage is modelled; no Roblox
-- locomotion, body posing, ceilings, networking or physics are simulated here.
local Movement=assert(loadstring(MOVEMENT_STATE_SOURCE))()
local checks=0
local function check(ok,label) assert(ok,label);checks+=1 end
local function near(a,b) return math.abs(a-b)<.00001 end
local function humanoid(speed)
    local data={speed=speed,attributes={},writes=0}
    local bytes=buffer.create(4)
    local object={}
    return setmetatable(object,{
        __index=function(_,key)
            if key=="WalkSpeed" then return data.speed end
            if key=="SetAttribute" then return function(_,name,value) data.attributes[name]=value end end
            if key=="GetAttribute" then return function(_,name) return data.attributes[name] end end
            if key=="Writes" then return data.writes end
        end,
        __newindex=function(_,key,value)
            assert(key=="WalkSpeed","Only the actual movement property may be assigned")
            buffer.writef32(bytes,0,value);data.speed=buffer.readf32(bytes,0);data.writes+=1
        end,
    })
end

do
    local h=humanoid(16)
    check(Movement.setBase(h,19,10) and h.WalkSpeed==19,"role sets an explicit full-speed baseline")
    check(h:GetAttribute("ZO_MoveBaseSpeed")==19 and h:GetAttribute("ZO_MovementMode")=="Run"
        and h:GetAttribute("ZO_TaggedUntil")==0,"public attributes describe the configured role")
    check(Movement.setMode(h,"Walk",.5,10) and h.WalkSpeed==9.5,"walking composes from the role base")
    check(Movement.setMode(h,"Crouch",.5,10) and h.WalkSpeed==9.5,"crouching does not multiply the prior walking reduction")
    check(Movement.setMode(h,"Run",1,10) and h.WalkSpeed==19,"run restores the original speed without a sprint boost")
    check(not Movement.setMode(h,"Sprint",1.5,10) and h.WalkSpeed==19,"unknown modes and boosted scales are rejected")
    check(not Movement.setBase(h,math.huge,10) and not Movement.setMode(h,"Walk",0/0,10),"invalid movement numbers cannot enter the state")
end

do
    local h=humanoid(19);Movement.setBase(h,19,10)
    local deadline=Movement.tag(h,10,.18,.55)
    check(near(h.WalkSpeed,10.45),"a hit applies the existing bounded containment factor")
    Movement.setMode(h,"Crouch",.5,10.05)
    check(near(h.WalkSpeed,5.225) and h:GetAttribute("ZO_TaggedUntil")==deadline,"changing stance keeps the active hit effect")
    Movement.step(h,deadline+.001)
    check(h.WalkSpeed==9.5 and h:GetAttribute("ZO_MovementMode")=="Crouch","tag expiry restores the current crouch speed rather than stale run speed")
    Movement.tag(h,11,.18,.55);Movement.setMode(h,"Run",1,11.05)
    check(near(h.WalkSpeed,10.45),"standing during a hit keeps containment until its deadline")
    Movement.step(h,11.2)
    check(h.WalkSpeed==19,"standing recovers full speed when the last hit expires")
end

do
    local h=humanoid(19);Movement.setBase(h,19,10);Movement.setMode(h,"Crouch",.5,10)
    for hit=1,40 do
        Movement.tag(h,10+hit*.1,.18,.55)
        check(near(h.WalkSpeed,5.225),"repeated crouched hits cannot compound float32 slowdown")
    end
    Movement.step(h,14.19)
    check(h.WalkSpeed==9.5,"a completed burst restores crouch speed exactly")
    local writes=h.Writes
    for step=1,100 do Movement.step(h,15+step*.01) end
    check(h.Writes==writes,"stable state never rewrites its rounded speed every frame")
end

do
    local h=humanoid(19);Movement.setBase(h,19,10);Movement.tag(h,10,.18,.55)
    h.WalkSpeed=23.7;local actual=h.WalkSpeed
    Movement.step(h,10.05)
    check(h.WalkSpeed==actual and h:GetAttribute("ZO_TaggedUntil")==0,"another system's newer speed cancels owned recovery without being overwritten")
    Movement.clearTag(h,true)
    check(h.WalkSpeed==actual,"obsolete tag cleanup cannot undo the external write")
    Movement.tag(h,11,.18,.55)
    check(near(h.WalkSpeed,actual*.55),"the next hit uses the explicitly observed external baseline")
    Movement.step(h,11.2)
    check(h.WalkSpeed==actual,"the external fractional baseline survives the next expiry")
end

do
    local h=humanoid(16);Movement.setBase(h,16,10);Movement.setMode(h,"Walk",.5,10);Movement.tag(h,10,.18,.55)
    Movement.setBase(h,19,10.05)
    check(h.WalkSpeed==19 and h:GetAttribute("ZO_MovementMode")=="Run"
        and h:GetAttribute("ZO_TaggedUntil")==0,"infection resets the human stance and old hit state to the zombie role base")
    Movement.step(h,11)
    check(h.WalkSpeed==19,"the old role's deadline cannot restore an obsolete human speed")
    Movement.setMode(h,"Walk",.5,11);Movement.tag(h,11,.18,.55);Movement.clearTag(h,true)
    check(h.WalkSpeed==9.5,"explicit tag cancellation restores the active walking mode")
    Movement.tag(h,12,.18,.55);local retained=h.WalkSpeed;Movement.clearTag(h,false)
    check(h.WalkSpeed==retained and h:GetAttribute("ZO_TaggedUntil")==0,"death/removal cleanup can release state without writing a stale speed")
    Movement.forget(h);Movement.step(h,20)
    check(h.WalkSpeed==retained,"forgotten characters cannot receive later movement updates")
    local replacement=humanoid(23);Movement.setBase(replacement,23,20)
    check(replacement.WalkSpeed==23,"replacement humanoids have independent state")
end

do
    local h=humanoid(19);Movement.setBase(h,19,10)
    Movement.tag(h,10,5,.01)
    check(near(h.WalkSpeed,1.9) and h:GetAttribute("ZO_TaggedUntil")==11,"untrusted duration and scale remain bounded by the prior containment policy")
    Movement.step(h,11)
    check(h.WalkSpeed==19,"bounded hit deadline expires normally")
end

print(("PASS movement composition: %d assertions; real module and float32 property double, no Roblox physics"):format(checks))
