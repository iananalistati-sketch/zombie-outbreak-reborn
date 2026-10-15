local Config=require("../../src/maps/k17/gameplay/Config")
local Rules=require("../../src/maps/k17/gameplay/Rules")
local WeaponState=require("../../src/maps/k17/gameplay/WeaponState")
local Round=require("../../src/maps/k17/gameplay/RoundRules")
local passed=0
local function check(ok,label) assert(ok,label);passed+=1 end
local function near(a,b) return math.abs(a-b)<.00001 end
local w=WeaponState.new(Config.Rifle)
check(w.ammo==30 and w.reserve==120,"initial magazine/reserve")
check(not w:reload(1),"full magazine cannot waste reserve")
check(w:fire(1),"first accepted shot")
check(w.ammo==29,"one round consumed")
check(not w:fire(1.01),"server cadence enforced")
check(w.ammo==29,"rejected shot consumes nothing")
check(w:reload(1.02),"reload accepted immediately after firing")
local finish=w.reloadEnds
check(not w:reload(1.5) and w.reloadEnds==finish,"repeated reload cannot restart or shorten deadline")
check(not w:fire(3),"cannot fire during reload")
check(not w:advance(finish-.01) and w.ammo==29 and w.reserve==120,"no ammunition transferred before completion")
check(w:advance(finish) and w.ammo==30 and w.reserve==119,"exact deadline transfers correct ammunition")
check(not w:advance(finish+1) and w.reserve==119,"completion is not applied twice")
check(w:fire(4),"shot after completion")
check(w:reload(4.1) and w:cancelReload(),"death/role/round cancellation")
check(not w:advance(100) and w.ammo==29 and w.reserve==119,"cancelled reload never transfers later")
w.ammo=27;w.reserve=2
check(w:reload(101),"partial reserve reload")
check(w:advance(104) and w.ammo==29 and w.reserve==0,"cannot invent ammunition with partial reserve")
check(not w:reload(105),"empty reserve blocks reload")
w=WeaponState.new(Config.Rifle)
for i=1,30 do check(w:fire(i),"valid firing sequence") end
check(w.ammo==0 and not w:fire(31),"empty magazine cannot fire")
w=WeaponState.new(Config.Rifle)
local accepted=0
for i=0,1000 do if w:fire(i/1000) then accepted+=1 end end
check(accepted<=math.floor(1/Config.Rifle.FireInterval)+1,"request flood cannot exceed server cadence")
check(w.ammo==30-accepted,"flood spends only accepted shots")
check(Rules.direction(0,0,-1) and Rules.direction(0,1,0),"normal horizontal/vertical directions")
for _,bad in {0/0,math.huge,-math.huge,{},true,"1"} do
    check(not Rules.direction(bad,0,-1),"invalid X rejected")
    check(not Rules.direction(0,bad,-1),"invalid Y rejected")
    check(not Rules.direction(0,0,bad),"invalid Z rejected")
end
check(not Rules.direction(0,0,0) and not Rules.direction(0,0,100),"zero/non-unit aim rejected")
check(Rules.facing(0,-1,0,-1) and not Rules.facing(0,1,0,-1),"front/back aim validation")
check(Rules.facing(0,0,0,-1),"straight vertical aim allowed")
for _,role in {"Humans","Zombies","Lobby"} do
    for _,phase in {"Waiting","Intermission","Preparation","Active","Results"} do
        check(Rules.canFire(role,phase,true,false)==(role=="Humans" and (phase=="Preparation" or phase=="Active")),"rifle role/phase matrix")
        check(not Rules.canFire(role,phase,false,false) and not Rules.canFire(role,phase,true,true),"dead/selecting cannot shoot")
        check(Rules.canMelee(role,phase,true)==(role=="Zombies" and phase=="Active"),"melee role/phase matrix")
        check(not Rules.canMelee(role,phase,false),"dead cannot melee")
    end
end
check(Rules.phase("Waiting",true,true,1)=="Active","solo Studio opt-in")
check(Rules.phase("Waiting",false,true,1)=="Waiting","practice impossible on live server")
check(Rules.phase("Waiting",true,true,2)=="Waiting","practice impossible with two players")
check(Rules.hitgroup("Head")=="Head" and Rules.hitgroup("RightUpperArm")=="Arm" and Rules.hitgroup("Left Foot")=="Leg" and Rules.hitgroup("Torso")=="Body","R6/R15 hitgroup mapping")
local body=Rules.knockback(Config,22,1,1,1,false)
check(near(body,27.5),"damage scaled body knockback")
check(near(Rules.knockback(Config,22,2,1,1,false),body*2),"weapon multiplier")
check(near(Rules.knockback(Config,22,1,1.2,1,false),body*1.2),"hitgroup multiplier")
check(near(Rules.knockback(Config,22,1,1,.5,false),body*.5),"class multiplier")
check(near(Rules.knockback(Config,22,1,1,1,true),body*Config.AirKnockback),"air multiplier")
check(Rules.knockback(Config,1000,1,1,1,false)==Config.MaxVelocityChange,"impulse cap")
check(Rules.knockback(Config,0/0,1,1,1,false)==0,"NaN damage rejected")
check(Round.motherCount(1,1/7)==0 and Round.motherCount(2,1/7)==1,"minimum players/mother")
check(Round.motherCount(21,1/7)==3 and Round.motherCount(2,10)==1,"ratio and remaining human")
local chosen=Round.choose({"a","b","c"},{a=true},1,function() return 1 end)
check(#chosen==1 and chosen[1]~="a","consecutive mother blocked when alternatives exist")
local fallback=Round.choose({"a","b"},{a=true,b=true},1,function() return 1 end)
check(#fallback==1,"mother cycle fallback cannot stall round")
check(Round.canInfect("Active","Zombies","Humans",true,true,true,true),"legitimate melee infection")
for i=1,4 do
    local flags={true,true,true,true};flags[i]=false
    check(not Round.canInfect("Active","Zombies","Humans",flags[1],flags[2],flags[3],flags[4]),"nonparticipants/dead cannot infect")
end
check(not Round.canInfect("Preparation","Zombies","Humans",true,true,true,true),"preparation cannot infect")
check(not Round.canInfect("Active","Humans","Humans",true,true,true,true),"human cannot infect")
check(not Round.canInfect("Active","Zombies","Zombies",true,true,true,true),"zombie cannot reinfect zombie")
check(Round.result(1,1,2,2,20)==nil,"round continues with opposing roles")
check(Round.result(0,2,2,2,20)=="Zombies","last human infected")
check(Round.result(1,1,2,2,0)=="Humans","timer survival")
check(Round.result(1,0,1,2,10)=="Cancelled","disconnect cannot award false victory")
print(("PASS classic gameplay: %d assertions against actual rules and weapon-state modules"):format(passed))
