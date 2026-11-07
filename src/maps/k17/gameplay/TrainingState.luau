--!strict
-- Pure warm-up state machine, driven by server time and confirmed actor deaths.
local State={};State.__index=State
function State.new(config,now,escapeSeconds)
    return setmetatable({config=config,stage="Intro",wave=1,spawned=0,kills=0,
        totalKills=0,deadline=now+config.IntroSeconds,nextSpawn=now,revision=0,escapeSeconds=escapeSeconds},State)
end
function State:finish(won,now)
    if self.stage=="Won" or self.stage=="Lost" then return end
    self.stage=if won then "Won" else "Lost";self.deadline=now+self.config.ResultSeconds
end
function State:kill()
    if self.stage~="Fighting" or self.kills>=self.spawned then return false end
    self.kills+=1;self.totalKills+=1;return true
end
function State:step(now,alive)
    if self.stage=="Won" or self.stage=="Lost" then return end
    if not alive then self.stage="Lost";self.deadline=now+self.config.ResultSeconds;return end
    if self.stage=="Intro" or self.stage=="Between" then
        if now>=self.deadline then
            self.stage="Fighting";self.deadline=now+(self.escapeSeconds or self.config.WaveSeconds);self.nextSpawn=now
        end
    elseif self.stage=="Fighting" then
        if self.escapeSeconds then return end -- EscapeSession owns extraction/timeout.
        if self.kills>=self.config.Waves[self.wave].Count then
            if self.wave==#self.config.Waves then
                self.stage="Won";self.deadline=now+self.config.ResultSeconds
            else
                self.wave+=1;self.spawned=0;self.kills=0
                self.stage="Between";self.deadline=now+self.config.BetweenWaves
            end
        elseif now>=self.deadline then self.stage="Lost";self.deadline=now+self.config.ResultSeconds end
    end
end
function State:canSpawn(now,liveCount)
    local settings=if self.escapeSeconds then self.config.Escape else self.config
    return self.stage=="Fighting" and now>=self.nextSpawn and liveCount<settings.MaxAlive
        and (self.escapeSeconds~=nil or self.spawned<self.config.Waves[self.wave].Count)
end
function State:spawn(now,liveCount)
    if not self:canSpawn(now,liveCount) then return false end
    local settings=if self.escapeSeconds then self.config.Escape else self.config
    self.spawned+=1;self.nextSpawn=now+settings.SpawnInterval;return true
end
function State.pickSpawn(points,position,minimum,maximum,clear,cursor)
    if not points then return nil end
    local chosen,best=nil,math.huge
    for offset=1,#points do
        local p=points[(cursor+offset-1)%#points+1]
        local dx,dy,dz=p[1]-position[1],p[2]+4-position[2],p[3]-position[3]
        local squared=dx*dx+dy*dy+dz*dz
        if math.abs(dy)<=6 and squared>=minimum^2 and squared<=maximum^2 and squared<best and clear(p) then chosen=p;best=squared end
    end
    return chosen
end
function State:restartDue(now)
    return (self.stage=="Won" or self.stage=="Lost") and now>=self.deadline
end
return table.freeze(State)
