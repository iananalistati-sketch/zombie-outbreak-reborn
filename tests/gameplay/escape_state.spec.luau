local State=require('../../src/maps/k17/gameplay/EscapeState')
local Config=require('../../src/maps/k17/gameplay/EscapeConfig')
local RoundRules=require('../../src/maps/k17/gameplay/RoundRules')
local checks=0
local function check(v,label)assert(v,label);checks+=1 end
check(RoundRules.mode({'Escape','Survival'},1)=='Escape' and RoundRules.mode({'Escape','Survival'},2)=='Survival'
    and RoundRules.mode({'Escape','Survival'},3)=='Escape','mode rotation remains deterministic')
check(RoundRules.mode(nil,1)=='Survival','legacy/test profile without rotation remains Survival')
check(State.contains({228,4,226},Config.Extraction),'safe bay contains standing player')
for _,p in {{228,4,250},{228,20,226},{0/0,4,226}} do check(not State.contains(p,Config.Extraction),'outside/roof/invalid coordinates are not extraction') end
local s=State.new(Config)
check(not s:activate(2,0),'cannot skip the first trigger')
check(s:step(100,260,1)==nil and s.stage==1,'waiting near extraction never skips objective sequence')
local time=100
for i,stage in Config.Stages do
    check(s:activate(i,time),'current objective accepts one activation')
    check(not s:activate(i,time),'repeated trigger cannot reset the hold')
    s:step(time+stage.HoldSeconds-.01,200,1)
    check(s.stage==i and s.status=='Holding','hold cannot complete early')
    time+=stage.HoldSeconds;s:step(time,200,0)
end
check(s.status=='Extraction','last defended objective opens the extraction window')
check(s:step(time+Config.ExtractionSeconds-.01,100,1)==nil,'entering bay does not prematurely end the round')
check(s:step(time+Config.ExtractionSeconds,100,1)=='Humans','living human in bay wins at extraction deadline')
check(s:step(time+999,0,0)=='Humans','confirmed result is immutable')
local expired=State.new(Config);check(expired:step(360,0,1)=='Zombies','Escape never awards human victory just for surviving the round timer')
local empty=State.new(Config);empty.stage=3;empty.status='Extraction';empty.deadline=10
check(empty:step(10,200,0)=='Zombies','empty safe zone loses even with humans elsewhere')
print(('PASS Escape state/rotation: %d checks'):format(checks))
