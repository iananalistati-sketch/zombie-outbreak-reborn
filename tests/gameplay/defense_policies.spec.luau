local Guide=require('../../src/maps/k17/gameplay/RouteGuide')
local Spectator=require('../../src/maps/k17/gameplay/SpectatorState')
local checks=0
local function check(v,label)assert(v,label);checks+=1 end
local route={{0,0,0},{10,0,0},{10,0,10},{10,-24,58}}
local point=Guide.next(route,{3,3,0},6)
check(point==route[2],'guidance targets the next turn rather than distant goal')
point=Guide.next(route,{9,3,0},6);check(point==route[3],'reaching a corner advances to the next leg')
local _,hint=Guide.next(route,{10,0,12},6);check(hint=='Desça a escadaria','vertical route change explicitly indicates descent')
_,hint=Guide.next({{0,-24,0},{0,0,48}},{0,-22,2},6);check(hint=='Suba a escadaria','return stairs indicate ascent')
point=Guide.next({{0,0,0}},{100,3,100},6);check(point[1]==0,'single-point route stays valid')
local loop={{0,0,0},{20,0,0},{20,0,20},{0,0,20},{0,0,0},{-20,0,0}}
point=Guide.next(loop,{0,0,0},6);check(point==loop[6],'route intersections prefer forward progress')
check(not Spectator.allowed('Humans',true,'Active'),'living combatants keep their camera')
check(Spectator.allowed('Zombies',false,'Active'),'dead infected may spectate while waiting to respawn')
check(Spectator.allowed('Lobby',true,'Active'),'late arrivals can watch')
check(not Spectator.allowed('Lobby',true,'Results') and not Spectator.allowed('Humans',false,'Training'),'results and solo training do not seize the camera')
check(Spectator.side('Humans','Active')=='Zombies','death-to-infection replication window cannot reveal living human shelters')
local rows={{Id=1,Role='Zombies',Alive=true,Ready=true},{Id=2,Role='Humans',Alive=true,Ready=true},
    {Id=3,Role='Zombies',Alive=true,Ready=true},{Id=4,Role='Zombies',Alive=false,Ready=true},
    {Id=5,Role='Zombies',Alive=true,Ready=false}}
local choices=Spectator.targets(rows,1,'Zombies')
check(#choices==1 and choices[1].Id==3,'filter excludes self, enemies, dead and unloaded actors')
check(Spectator.pick({},nil)==nil,'empty observer list is safe')
check(Spectator.pick({{Id=1},{Id=2}},2,1).Id==1,'cycling wraps forward')
check(Spectator.pick({{Id=1},{Id=2}},1,-1).Id==2,'cycling wraps backward')
print(('PASS defense navigation/spectator policies: %d checks'):format(checks))
