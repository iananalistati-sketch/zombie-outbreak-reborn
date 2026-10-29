-- Execute the actual helper with a track timeline, not Roblox's animator.
-- The kit's two-second aim clips encode pitch: 1s is the neutral pose.
local AimPose=assert(loadstring(AIM_POSE_SOURCE))()
local checks=0
local function check(value,label) assert(value,label);checks+=1 end
local function near(a,b) return math.abs(a-b)<1e-6 end

local function track(length)
    local data={Length=length,IsPlaying=false,Speed=1,TimePosition=0,Looped=false}
    local calls,callbacks={},{}
    local value={}
    local methods={}
    function methods:Play(fade,weight,speed)
        table.insert(calls,{"Play",fade,weight,speed})
        data.IsPlaying=true;data.Speed=speed or 1;data.TimePosition=0
    end
    function methods:AdjustSpeed(speed)
        table.insert(calls,{"AdjustSpeed",speed});data.Speed=speed
    end
    function methods:Stop()
        table.insert(calls,{"Stop"});data.IsPlaying=false;data.TimePosition=0
    end
    function methods:GetPropertyChangedSignal(property)
        assert(property=="Length","Unexpected track signal: "..property)
        return {Connect=function(_,callback)
            table.insert(callbacks,callback)
            return {Disconnect=function()
                local index=table.find(callbacks,callback)
                if index then table.remove(callbacks,index) end
            end}
        end}
    end
    setmetatable(value,{
        __index=function(_,key) return methods[key] or data[key] end,
        __newindex=function(_,key,new)
            if key=="TimePosition" then
                assert(data.IsPlaying,"Roblox seek requires a playing track")
                table.insert(calls,{"Seek",new})
            end
            local changed=data[key]~=new;data[key]=new
            if key=="Length" and changed then
                for _,callback in table.clone(callbacks) do callback() end
            end
        end,
    })
    local function advance(seconds)
        if not data.IsPlaying then return end
        data.TimePosition+=data.Speed*seconds
        if data.Length>0 and data.TimePosition>=data.Length then
            if data.Looped then data.TimePosition%=data.Length
            else data.TimePosition=data.Length;data.IsPlaying=false end
        end
    end
    local function plays()
        local count=0
        for _,call in calls do if call[1]=="Play" then count+=1 end end
        return count
    end
    return value,advance,calls,plays
end

do
    -- Reproduce the old integration's speed-1 loop traversing the pitch bank.
    local old,advance=track(2)
    old.Looped=true;old:Play(.12,1,1)
    advance(.25);check(near(old.TimePosition,.25),"old aim loop first samples downward-pitch region")
    advance(1);check(near(old.TimePosition,1.25),"old aim loop drifts past neutral toward upward-pitch region")
end

do
    local aim,advance,calls,plays=track(2)
    local connection=AimPose.bind(aim)
    check(not aim.IsPlaying and plays()==0,"binding a pose never starts playback")
    AimPose.hold(aim,.23)
    check(aim.IsPlaying and plays()==1,"holding a stopped pose starts it once")
    check(calls[1][1]=="Play" and calls[1][4]==0,"pose starts at zero playback speed before any seek")
    check(calls[1][2]==.23,"requested blend time reaches the animation track")
    local firstSeek
    for index,call in calls do if call[1]=="Seek" then firstSeek=index;break end end
    check(firstSeek and firstSeek>1,"neutral seek happens after Play")
    check(near(aim.TimePosition,1) and aim.Speed==0,"loaded kit pose holds its neutral one-second frame")
    check(aim.Looped==false,"pose is not configured as a pitch-sweeping idle loop")
    advance(2.4)
    check(aim.IsPlaying and near(aim.TimePosition,1),"aim remains neutral beyond the original two-second clip duration")
    AimPose.hold(aim,.4);advance(10)
    check(plays()==1 and near(aim.TimePosition,1),"repeated hold does not restart the track or drift over time")
    -- An already playing pose must also be corrected without restarting it.
    aim:AdjustSpeed(.75);aim.TimePosition=.2;AimPose.hold(aim)
    check(plays()==1 and aim.Speed==0 and near(aim.TimePosition,1),"existing moving pose is frozen and re-centred without another Play")
    connection:Disconnect()
    aim.TimePosition=.3;aim.Length=3
    check(near(aim.TimePosition,.3),"disconnecting binding stops late Length callbacks")
end

do
    local aim,advance,_,plays=track(0)
    local connection=AimPose.bind(aim)
    AimPose.hold(aim)
    check(aim.IsPlaying and aim.Speed==0,"unloaded aim starts frozen while Length is zero")
    check(aim.TimePosition==0,"unloaded aim does not seek an unavailable neutral frame")
    aim.Length=2
    check(near(aim.TimePosition,1) and plays()==1,"late animation load seeks neutral without restarting playback")
    advance(2.5)
    check(near(aim.TimePosition,1) and aim.IsPlaying,"late-loaded aim stays neutral after a full clip duration")
    aim:Stop();local position=aim.TimePosition
    aim.Length=2.2
    check(not aim.IsPlaying and plays()==1,"Length arriving after Stop never resurrects the aim track")
    check(aim.TimePosition==position,"stopped track is not re-seeked by a loading callback")
    AimPose.hold(aim)
    check(aim.IsPlaying and plays()==2 and near(aim.TimePosition,1),"explicit hold can start a previously stopped pose again")
    connection:Disconnect()
end

do
    local aim,advance=track(.6)
    AimPose.hold(aim)
    local position=aim.TimePosition
    check(position>.59 and position<aim.Length,"short clip clamps neutral seek safely before its end")
    advance(3)
    check(aim.IsPlaying and near(aim.TimePosition,position),"short clip remains frozen instead of advancing or stopping")
end

print(("PASS weapon aim pose adapter: %d checks (timeline/API doubles; no Roblox animator)"):format(checks))
