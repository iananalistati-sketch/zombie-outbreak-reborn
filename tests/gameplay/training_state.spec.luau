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
print("PASS training state and phase authority: "..checks.." checks")
