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
local west={{-220,-20,-100}}
check(State.advanceCheckpoint(Config,0,1,west)==0,'standing downstream cannot bypass an unfinished objective')
check(State.advanceCheckpoint(Config,0,2,{{144,5,-224}})==0,'completing generator alone cannot advance spawns ahead of humans')
check(State.advanceCheckpoint(Config,0,2,{{-220,5,-100}})==0,'surface position over underground sector cannot unlock it')
check(State.advanceCheckpoint(Config,0,2,west)==1,'living humans reaching west ring unlock north descent return')
check(State.advanceCheckpoint(Config,1,2,{{0,-20,178}})==1,'pump defense must complete before second return unlocks')
check(State.advanceCheckpoint(Config,1,3,{{0,-20,178}})==2,'downstream traversal after pumps unlocks second return')
check(State.advanceCheckpoint(Config,2,3,{})==2,'unlocked checkpoint does not regress when humans move or die')
local function free()return true end
local p,group=State.chooseSpawn(Config,2,{},free,0)
check(p==Config.Respawns[2].Points[1]and group==2,'newest unlocked clear group is preferred')
local nextPoint=State.chooseSpawn(Config,2,{},free,1)
check(nextPoint~=p,'cursor spreads returns across authored positions')
local fallback,fallbackGroup=State.chooseSpawn(Config,2,{},function(point)return point[1]>=0 end,0)
check(fallbackGroup==1 and fallback~=nil,'occupied latest group falls back to an earlier unlocked group')
local distant,distantGroup=State.chooseSpawn(Config,2,{{-152,-20,144}},free,0)
check(distantGroup==1 and distant~=nil,'nearby human excludes all close candidates in the latest group')
check(State.chooseSpawn(Config,2,{},function()return false end,0)==nil,'no clear candidate yields no unsafe teleport')
check(State.chooseSpawn(Config,0,{{-68,5,-238}},free,0)==nil,'initial candidates also respect human distance')
local boundary={SpawnDistance=48,InitialSpawns={{0,0,0}}}
check(State.chooseSpawn(boundary,0,{{47.99,4,0}},free,0)==nil,'distance uses the actual root height and rejects a human inside 48 studs')
check(State.chooseSpawn(boundary,0,{{48,4,0}},free,0)~=nil,'exact safe boundary accepts a clear spawn')
print(('PASS Escape state/rotation/respawn policy: %d checks'):format(checks))
