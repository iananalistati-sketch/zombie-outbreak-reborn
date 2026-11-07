local Config=require("../../src/maps/k17/gameplay/TrainingConfig")
local State=require("../../src/maps/k17/gameplay/TrainingState")
local Rules=require("../../src/maps/k17/gameplay/Rules")
local BarRules=require("../../src/maps/k17/barricades/Rules")
local checks=0
local function check(v,label)assert(v,label);checks+=1 end
for _,r in {Rules,BarRules} do
    check(r.phase("Training",false,true,1)=="Active","solo warm-up works without Studio permissions")
    check(r.phase("Training",false,true,2)=="Waiting","a second player immediately closes training privileges")
    check(r.phase("Training",false,false,1)=="Waiting","missing server practice flag cannot activate training combat")
    check(r.phase("Waiting",false,true,1)=="Waiting","the legacy Studio-only override remains restricted")
end
do
    local s=State.new(Config,0)
    check(s.stage=="Intro" and not s:spawn(0,0),"intro cannot spawn enemies")
    check(not s:kill(),"kills before fighting cannot count")
    s:step(4.99,true);check(s.stage=="Intro","intro duration is respected")
    s:step(5,true);check(s.stage=="Fighting","warm-up enters first wave")
    check(s:spawn(5,0) and s.spawned==1,"first spawn is admitted")
    check(not s:spawn(5,0),"duplicate spawn in same frame is rejected")
    check(s:kill() and not s:kill(),"a kill cannot exceed admitted spawns")
    check(s:spawn(7,0) and s:spawn(9,1),"remaining first wave actors can spawn")
    check(not s:spawn(11,2),"wave cannot exceed authored count")
    s:kill();s:kill();s:step(10,true)
    check(s.stage=="Between" and s.wave==2 and s.totalKills==3,"first wave completion preserves total kills")
    check(not s:kill() and not s:spawn(11,0),"intermission rejects late kills and spawns")
    s:step(14,true)
    check(s:spawn(14,0) and s:spawn(16,1) and s:spawn(18,2),"second wave fills the concurrent budget")
    check(not s:spawn(20,3),"maximum concurrent actors enforced")
    s:kill();check(s:spawn(20,2),"kill frees a spawn slot")
    for _=1,3 do s:kill() end
    s:step(21,true);s:step(25,true)
    for i=1,5 do check(s:spawn(25+(i-1)*2,0) and s:kill(),"last wave finite spawn and kill") end
    s:step(34,true)
    check(s.stage=="Won" and s.totalKills==12,"all three waves resolve to victory")
    check(not s:restartDue(39.99) and s:restartDue(40),"result duration and automatic restart deadline respected")
    check(not s:spawn(40,0) and not s:kill(),"terminal wave cannot continue awarding progress")
end
do
    local s=State.new(Config,0);s:step(5,true);s:step(95,true)
    check(s.stage=="Lost","timeout is a visible result instead of a stuck wave")
    local s2=State.new(Config,0);s2:step(1,false)
    check(s2.stage=="Lost" and s2:restartDue(7),"player death produces a retry deadline")
    s2:step(2,true);check(s2.stage=="Lost","a fast respawn cannot skip the result")
end
do
    local s=State.new(Config,0,360);s:step(Config.IntroSeconds,true)
    for i=1,12 do
        local now=Config.IntroSeconds+(i-1)*Config.Escape.SpawnInterval
        check(s:spawn(now,0)and s:kill(),'objective exercise supports continuing pressure beyond old finite waves')
        s:step(now,true)
    end
    check(s.stage=='Fighting'and s.wave==1,'twelve NPC kills cannot replace extraction victory')
    check(not s:canSpawn(100,Config.Escape.MaxAlive),'objective pressure honors its concurrent budget')
    s:step(500,true);check(s.stage=='Fighting','global Escape timeout belongs to EscapeSession, not the wave ticker')
    s:finish(true,500);check(s.stage=='Won'and s:restartDue(506),'confirmed exercise extraction uses normal retry deadline')
    s:finish(false,501);check(s.stage=='Won','terminal exercise result cannot flip')
end
do
    local points={{0,1,40},{0,1,32},{0,1,20},{0,15,35}}
    local p=State.pickSpawn(points,{0,5,0},28,95,function()return true end,0)
    check(p==points[2],'pressure prefers nearest safe authored point outside minimum distance')
    check(State.pickSpawn(points,{0,5,0},28,95,function()return false end,0)==nil,'occupied/visible points cannot create enemies')
    check(State.pickSpawn({{0,15,35}},{0,5,0},28,95,function()return true end,0)==nil,'pressure cannot materialize on another floor')
    check(State.pickSpawn({{0,1,96}},{0,5,0},28,95,function()return true end,0)==nil,'distant candidates cannot consume spawn slots')
end
print("PASS training state and phase authority: "..checks.." checks")
