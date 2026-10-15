-- Run with the official Luau CLI from the repository root.
local Rules=require("../../src/maps/k17/barricades/Rules")
local Config=require("../../src/maps/k17/barricades/Config")
local passed=0
local function check(value, label)
    assert(value,label);passed+=1
end
local function candidate(kind,x,z,quarter,rx,ry,rz)
    return Rules.candidate(Config.Zone,Config.Kinds[kind],x,z,quarter,rx or -247,ry or 4,rz or 123,Config.PlacementRange)
end
check(candidate("Cabinet",-245,123,0),"cabinet inside stockroom")
check(candidate("Cabinet",-225,123,1,-229,4,123),"rotated cabinet can cross real corridor doorway")
check(candidate("Crate",-244,100,0,-244,4,105),"adjacent-room doorway remains buildable")
check(not candidate("Cabinet",-260,123,0,-254,4,123),"reject footprint across west exterior wall")
check(candidate("Cabinet",-260,123,1,-254,4,123),"quarter turn changes footprint correctly")
check(not candidate("Table",-217,123,0,-222,4,123),"cannot export prop into corridor")
check(not candidate("Crate",-247,150,0,-247,4,143),"cannot leave room bounds")
check(not candidate("Crate",-247,123,0,-247,18,123),"upper floor cannot manipulate ground floor")
check(not candidate("Crate",-247,123,0,-247,-20,123),"underground cannot manipulate stockroom")
check(not candidate("Crate",-225,123,0),"placement beyond reach")
for _,bad in {0/0,math.huge,-math.huge,"100",{},true} do
    check(not candidate("Crate",bad,123,0),"invalid X rejected")
    check(not candidate("Crate",-247,bad,0),"invalid Z rejected")
    check(not candidate("Crate",-247,123,bad),"invalid rotation rejected")
end
for _,bad in {-1,4,.5,90} do check(not candidate("Crate",-247,123,bad),"only quarter-turn indices accepted") end
for _,role in {"Humans","Zombies","Lobby"} do
    for _,state in {"Waiting","Intermission","Preparation","Active","Results"} do
        check(Rules.canBuild(role,state,true)==(role=="Humans" and (state=="Preparation" or state=="Active")),"build phase/role matrix")
        check(Rules.canAttack(role,state,true)==(role=="Zombies" and state=="Active"),"attack phase/role matrix")
        check(not Rules.canBuild(role,state,false) and not Rules.canAttack(role,state,false),"dead players cannot interact")
    end
end
check(Rules.phase("Waiting",true,true,1)=="Active","explicit solo Studio practice")
check(Rules.phase("Waiting",false,true,1)=="Waiting","practice forbidden on live servers")
check(Rules.phase("Waiting",true,true,2)=="Waiting","practice forbidden with multiple players")
check(Rules.phase("Waiting",true,false,1)=="Waiting","practice opt in")
check(Rules.phase("Preparation",true,true,1)=="Preparation","practice cannot override real round")
check(math.ceil(Config.Kinds.Cabinet.Health/Config.MeleeDamage)==8,"cabinet durability target")
check(math.ceil(Config.Kinds.Table.Health/Config.MeleeDamage)==5,"table durability target")
check(math.ceil(Config.Kinds.Crate.Health/Config.MeleeDamage)==4,"crate durability target")
print(("PASS barricade rules: %d assertions, real policy module executed"):format(passed))
