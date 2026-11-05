--!strict
-- Shared movement authority: role speed, stance and temporary hit tagging compose
-- from a stored baseline. Never use our own reduced WalkSpeed as a new baseline.
-- Tag duration/scale follow the existing K-17 Containment policy.
local MovementState={}
type State={base: number,mode: string,modeScale: number,untilTime: number,
    tagScale: number,applied: number,desired: number?}
local states: {[Humanoid]: State}=setmetatable({},{__mode="k"}) :: any
local modes={Run=true,Walk=true,Crouch=true,Sprint=true}

local function finite(value: any): boolean
    return type(value)=="number" and value==value and math.abs(value)<1e6
end
local function state(hum: Humanoid): State
    local current=states[hum]
    if current then return current end
    local speed=if finite(hum.WalkSpeed) then math.clamp(hum.WalkSpeed,0,200) else 0
    current={base=speed,mode="Run",modeScale=1,untilTime=0,tagScale=1,applied=hum.WalkSpeed,desired=nil}
    states[hum]=current
    return current
end
local function publish(hum: Humanoid,current: State)
    hum:SetAttribute("ZO_MoveBaseSpeed",current.base)
    hum:SetAttribute("ZO_MovementMode",current.mode)
    hum:SetAttribute("ZO_TaggedUntil",current.untilTime)
end
local function observeExternal(hum: Humanoid,current: State): boolean
    if hum.WalkSpeed==current.applied then return false end
    -- Preserve another system's newer write. It is the untagged speed for the
    -- current stance; the next explicit mode/tag request can compose it again.
    if finite(hum.WalkSpeed) then current.base=math.clamp(hum.WalkSpeed/current.modeScale,0,200) end
    current.untilTime=0;current.tagScale=1
    current.applied=hum.WalkSpeed;current.desired=nil
    publish(hum,current)
    return true
end
local function apply(hum: Humanoid,current: State,now: number)
    if now>=current.untilTime then current.untilTime=0;current.tagScale=1 end
    local desired=current.base*current.modeScale*(if current.untilTime>now then current.tagScale else 1)
    if desired~=current.desired or hum.WalkSpeed~=current.applied then
        hum.WalkSpeed=desired
        -- Engine float storage differs from Luau doubles. Own the readback.
        current.applied=hum.WalkSpeed
        current.desired=desired
    end
    publish(hum,current)
end

function MovementState.setBase(hum: Humanoid,base: number,now: number?): boolean
    if not finite(base) or base<0 or base>200 then return false end
    local current=state(hum)
    current.base=base;current.mode="Run";current.modeScale=1
    current.untilTime=0;current.tagScale=1;current.desired=nil
    apply(hum,current,now or os.clock())
    return true
end

function MovementState.setMode(hum: Humanoid,mode: string,scale: number,now: number?): boolean
    if not modes[mode] or not finite(scale) then return false end
    -- Only the explicitly named sprint mode can exceed the role's normal
    -- speed. Callers still choose a bounded server configuration, never a
    -- speed supplied by the remote client.
    if mode=="Sprint" then
        if scale<1 or scale>1.5 then return false end
    elseif scale<=0 or scale>1 then return false end
    local current=state(hum)
    observeExternal(hum,current)
    current.mode=mode;current.modeScale=scale
    apply(hum,current,now or os.clock())
    return true
end

function MovementState.tag(hum: Humanoid,now: number,seconds: number,scale: number): number
    local current=state(hum)
    if not finite(now) or not finite(seconds) or seconds<=0 or not finite(scale) then return current.untilTime end
    observeExternal(hum,current)
    current.untilTime=math.max(current.untilTime,now+math.min(seconds,1))
    current.tagScale=math.clamp(scale,.1,1)
    apply(hum,current,now)
    return current.untilTime
end

function MovementState.clearTag(hum: Humanoid,restore: boolean?)
    local current=states[hum]
    if not current then return end
    local external=observeExternal(hum,current)
    current.untilTime=0;current.tagScale=1
    if restore~=false and not external then apply(hum,current,os.clock())
    else publish(hum,current) end
end

function MovementState.step(hum: Humanoid,now: number)
    local current=states[hum]
    if not current or not finite(now) then return end
    if observeExternal(hum,current) then return end
    apply(hum,current,now)
end

function MovementState.forget(hum: Humanoid)
    states[hum]=nil
end

return table.freeze(MovementState)
