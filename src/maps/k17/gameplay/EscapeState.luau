--!strict
-- Counter-Strike ZE-style sequence: trigger, defend, advance, final safe zone.
-- Original Luau policy; no Source/Workshop map or plugin code is copied.
local State={}
function State.contains(point: {number},bounds: any): boolean
    for i=1,3 do
        if point[i]~=point[i] or point[i]<bounds.Min[i] or point[i]>bounds.Max[i] then return false end
    end
    return true
end
function State.new(config: any)
    local self={config=config,stage=1,status="Ready",deadline=0,result=nil}
    function self:activate(index: number,now: number): boolean
        if self.status~="Ready" or self.stage~=index then return false end
        self.status="Holding";self.deadline=now+self.config.Stages[index].HoldSeconds
        return true
    end
    function self:step(now: number,remaining: number,safeHumans: number): string?
        if self.result then return self.result end
        if remaining<=0 then self.status="Done";self.result="Zombies";return self.result end
        if self.status=="Holding" and now>=self.deadline then
            if self.stage<#self.config.Stages then self.stage+=1;self.status="Ready";self.deadline=0
            else self.status="Extraction";self.deadline=now+self.config.ExtractionSeconds end
        elseif self.status=="Extraction" and now>=self.deadline then
            self.status="Done";self.result=if safeHumans>0 then "Humans" else "Zombies"
        end
        return self.result
    end
    return self
end
return table.freeze(State)
