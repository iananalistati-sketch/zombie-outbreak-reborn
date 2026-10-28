-- Actual server controllers share one world, player set, clock and Infect binding.
-- Ray intersections, service events and character respawn are API doubles.
local Config=assert(loadstring(CONFIG_SOURCE))()
local Rules=assert(loadstring(RULES_SOURCE))()
local WeaponState=assert(loadstring(WEAPON_SOURCE))()
local Containment=assert(loadstring(CONTAINMENT_SOURCE))()
local RoundConfig=assert(loadstring(ROUND_CONFIG_SOURCE))()
local RoundRules=assert(loadstring(ROUND_RULES_SOURCE))()
local MapConfig=assert(loadstring(MAP_CONFIG_SOURCE))()
local dependency={}
local loadout=assert(loadstring(LOADOUT_SOURCE))
setfenv(loadout,setmetatable({script={Parent={WeaponState=dependency}},require=function(module)
    assert(module==dependency);return WeaponState
end},{__index=getfenv()}))
local tools=assert(loadstring(SIMULATION_SOURCE))()({Config=Config,Rules=Rules,WeaponState=WeaponState,
    Containment=Containment,LoadoutState=loadout(),CombatSource=COMBAT_SOURCE})
local s=tools.simulation({roundSource=ROUND_SOURCE,startupSource=STARTUP_SOURCE,
    roundConfig=RoundConfig,roundRules=RoundRules,mapConfig=MapConfig})
local checks=0
local function check(ok,label) assert(ok,label);checks+=1 end
local function attr(p,key) return p:GetAttribute('ZO_'..key) end
local function untilState(state,timeout)
    local deadline=s.now()+timeout
    while s.rs:GetAttribute('ZO_RoundState')~=state and s.now()<deadline do s.advance(.05) end
    check(s.rs:GetAttribute('ZO_RoundState')==state,'reaches '..state..' within bounded time')
end
local function roles()
    local human,zombie
    for _,p in s.players:GetPlayers() do
        if p.Team.Name=='Humans' then human=p elseif p.Team.Name=='Zombies' then zombie=p end
    end
    assert(human and zombie,'one human and one zombie');return human,zombie
end
local function hit(model)
    return {Instance=model.UpperTorso,Position=model.UpperTorso.Position,Normal=tools.Vector.yAxis}
end

check(s.rs:GetAttribute('ZO_GameplayStatus')=='Ready','Startup observes both actual controllers ready')
local a=s.add('A');local b=s.add('B')
untilState('Preparation',RoundConfig.Intermission+1)
check(a.Team.Name=='Humans' and b.Team.Name=='Humans','both participants start as humans')
check(attr(a,'Ammo')==Config.Weapons.Rifle.Magazine,'real round transition gives a loaded starter rifle')
local pivotsA,pivotsB=a.Character.PivotCount,b.Character.PivotCount
untilState('Active',RoundConfig.Preparation+1)
local human,zombie=roles()
local firstMother=zombie
check(s.rs:GetAttribute('ZO_Humans')==1 and s.rs:GetAttribute('ZO_Zombies')==1,'first infection updates actual participant counts')
check(a.Character.PivotCount==pivotsA and b.Character.PivotCount==pivotsB,'first infected transforms in place')
local late=s.add('Late')
check(late.Team.Name=='Lobby','late joiner waits instead of entering the active round')
s.remove(late)

local health=zombie.Character.Humanoid.Health
local ammo=attr(human,'Ammo')
s.ray(function() return hit(zombie.Character) end);s.fire(human)
check(zombie.Character.Humanoid.Health==health-Config.Weapons.Rifle.Damage,'real Combat damages the zombie selected by real Round')
check(attr(human,'Ammo')==ammo-1,'damage costs server-owned ammunition')
s.advance(.05);s.reload(human)
check(attr(human,'Reloading')==true,'reload starts during the active round')
s.advance(Config.Weapons.Rifle.ReloadSeconds+.1)
check(attr(human,'Ammo')==ammo and attr(human,'Reloading')==false,'reload finishes on server timer')
s.fire(human);s.advance(.05);s.reload(human)
local infectionCredits=attr(zombie,'Credits')
s.ray(function() return hit(human.Character) end);s.melee(zombie)
check(human.Team.Name=='Zombies' and attr(human,'InfectedBy')==zombie.UserId,'real melee invokes real infection authority')
check(attr(human,'Reloading')==false,'infection cancels the real in-progress reload')
check(attr(zombie,'Credits')==infectionCredits+Config.Economy.InfectionReward,'confirmed infection pays once')
untilState('Results',1)
check(s.rs:GetAttribute('ZO_LastWinner')=='Zombies','infecting the final human produces zombie victory')
check(attr(a,'SurvivedRound')==0 and attr(b,'SurvivedRound')==0,'infected players receive no human survival snapshot')

untilState('Preparation',RoundConfig.Results+RoundConfig.Intermission+1)
check(s.rs:GetAttribute('ZO_RoundId')==2,'next round starts automatically')
check(a.Team.Name=='Humans' and b.Team.Name=='Humans','round restart restores both human roles')
untilState('Active',RoundConfig.Preparation+1)
human,zombie=roles()
check(zombie~=firstMother,'first infected rotates when an alternative exists')
local killCredits=attr(human,'Credits')
s.ray(function() return hit(zombie.Character) end)
while zombie.Character.Humanoid.Health>0 do s.fire(human);s.advance(Config.Weapons.Rifle.FireInterval+.001) end
check(attr(human,'Credits')==killCredits+Config.Economy.KillReward,'actual lethal damage grants one kill reward')
check(zombie.Team.Name=='Zombies' and s.rs:GetAttribute('ZO_RoundState')=='Active','dead zombie retains its role while awaiting respawn')
-- The engine's auto-respawn is represented by a CharacterAdded event here.
s.character(zombie);s.advance(.05)
check(zombie.Character.Humanoid.Health==RoundConfig.ZombieHealth,'replacement zombie receives configured health')
check(zombie.Character.Humanoid.WalkSpeed==RoundConfig.ZombieWalkSpeed,'replacement zombie receives configured speed')
local survivalCredits=attr(human,'Credits')
local zombieCredits=attr(zombie,'Credits')
untilState('Results',RoundConfig.Duration+1)
check(s.rs:GetAttribute('ZO_LastWinner')=='Humans','remaining human wins when the actual round clock expires')
check(attr(human,'SurvivedRound')==2,'living human is captured before Lobby cleanup')
check(attr(human,'Credits')==survivalCredits+Config.Economy.SurvivalReward,'survival pays exactly once across Results and Lobby callbacks')
check(attr(zombie,'Credits')==zombieCredits,'zombie does not receive human survival income')
untilState('Preparation',RoundConfig.Results+RoundConfig.Intermission+1)
check(s.rs:GetAttribute('ZO_RoundId')==3,'a third round starts after human victory')
untilState('Active',RoundConfig.Preparation+1)
human,zombie=roles();s.remove(zombie)
untilState('Results',1)
check(s.rs:GetAttribute('ZO_LastWinner')=='Cancelled','dropping below minimum cancels without a false human victory')
untilState('Waiting',RoundConfig.Results+1)
check(#s.errors==0,'no server controller runtime errors across the three-round scenario')
print(('PASS integrated Survival: %d assertions; actual Round + Combat + Startup, API doubles; Studio not executed'):format(checks))
