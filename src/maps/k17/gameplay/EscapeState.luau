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
-- A completed defense alone cannot spawn infection ahead of the fleeing group.
-- At least one living participant must actually reach the downstream sector.
function State.advanceCheckpoint(config: any,current: number,stage: number,positions: {{number}}): number
    for index,checkpoint in config.Respawns or {} do
        if index<=current or stage<=checkpoint.AfterStage then continue end
        for _,position in positions do
            if State.contains(position,checkpoint.Advance) then current=index;break end
        end
    end
    return current
end
function State.chooseSpawn(config: any,checkpoint: number,positions: {{number}},clear: any,cursor: number): ({number}?,number?)
    local distance=(config.SpawnDistance or 48)^2
    -- Try unlocked groups newest-first; blocked/unsafe sectors fall back to an
    -- earlier group. If none is safe, the round queues the respawn and retries.
    for group=checkpoint,0,-1 do
        local points=if group==0 then config.InitialSpawns or {config.MotherSpawn} else config.Respawns[group].Points
        for offset=1,#points do
            local point=points[(cursor+offset-1)%#points+1]
            local safe=true
            for _,human in positions do
                -- Authored points are floor coordinates; actual spawn root is +4.
                local dx,dy,dz=human[1]-point[1],human[2]-(point[2]+4),human[3]-point[3]
                if dx*dx+dy*dy+dz*dz<distance then safe=false;break end
            end
            if safe and clear(point) then return point,group end
        end
    end
    return nil,nil
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
