--!strict
-- Pure warm-up state machine, driven by server time and confirmed actor deaths.
local State={};State.__index=State
function State.new(config,now)
    return setmetatable({config=config,stage="Intro",wave=1,spawned=0,kills=0,
        totalKills=0,deadline=now+config.IntroSeconds,nextSpawn=now,revision=0},State)
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
            self.stage="Fighting";self.deadline=now+self.config.WaveSeconds;self.nextSpawn=now
        end
    elseif self.stage=="Fighting" then
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
function State:spawn(now,liveCount)
    if self.stage~="Fighting" or now<self.nextSpawn or liveCount>=self.config.MaxAlive
        or self.spawned>=self.config.Waves[self.wave].Count then return false end
    self.spawned+=1;self.nextSpawn=now+self.config.SpawnInterval;return true
end
function State:restartDue(now)
    return (self.stage=="Won" or self.stage=="Lost") and now>=self.deadline
end
return table.freeze(State)
