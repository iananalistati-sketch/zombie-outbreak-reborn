--!strict
-- Cosmetic magazine prediction only. Server snapshots remain authoritative.
local Prediction={};Prediction.__index=Prediction
function Prediction.new()
    return setmetatable({id="",confirmed=0,observed=0,serial=0,lastAck=0,pending={}},Prediction)
end
function Prediction:reset(id: string,ammo: number)
    self.id=id;self.confirmed=math.max(0,ammo);self.observed=self.confirmed
    table.clear(self.pending)
end
function Prediction:sync(id: string,ammo: number)
    if id~=self.id then self:reset(id,ammo);return end
    if ammo==self.observed then return end
    local before=self.observed;self.observed=ammo
    if ammo>before then
        self:reset(id,ammo) -- authoritative reload/refill
    elseif next(self.pending)==nil then
        -- Attribute replication may trail a newer acknowledgement. Never undo
        -- confirmed expenditure with an older, larger magazine snapshot.
        self.confirmed=math.min(self.confirmed,ammo)
    end
end
function Prediction:ammo(): number
    local count=0;for _ in self.pending do count+=1 end
    return math.max(0,self.confirmed-count)
end
function Prediction:stalled(now: number): boolean
    for _,time in self.pending do if now-time>1.5 then return true end end
    return false
end
function Prediction:fire(now: number): number?
    if self:ammo()<=0 or self:stalled(now) then return nil end
    self.serial+=1;self.pending[self.serial]=now;return self.serial
end
function Prediction:ack(id: string,serial: number,ammo: number): boolean
    if id~=self.id or not self.pending[serial] or serial<=self.lastAck then return false end
    self.lastAck=serial;self.confirmed=math.max(0,ammo)
    for key in self.pending do if key<=serial then self.pending[key]=nil end end
    return true
end
return table.freeze(Prediction)
