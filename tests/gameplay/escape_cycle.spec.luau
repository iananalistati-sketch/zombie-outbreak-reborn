-- The real four server sources share one clock/world. No Roblox physics runs.
local Config=assert(loadstring(CONFIG_SOURCE))()
local Rules=assert(loadstring(RULES_SOURCE))()
local WeaponState=assert(loadstring(WEAPON_SOURCE))()
local Containment=assert(loadstring(CONTAINMENT_SOURCE))()
local MovementState=assert(loadstring(MOVEMENT_STATE_SOURCE))()
local WeaponSkins=assert(loadstring(WEAPON_SKINS_SOURCE))()
local RoundStats=assert(loadstring(ROUND_STATS_SOURCE))()
local RoundConfig=assert(loadstring(ROUND_CONFIG_SOURCE))()
local RoundRules=assert(loadstring(ROUND_RULES_SOURCE))()
local MapConfig=assert(loadstring(MAP_CONFIG_SOURCE))()
local EscapeConfig=assert(loadstring(ESCAPE_CONFIG_SOURCE))()
local EscapeState=assert(loadstring(ESCAPE_STATE_SOURCE))()
local dependency={};local loadout=assert(loadstring(LOADOUT_SOURCE))
setfenv(loadout,setmetatable({script={Parent={WeaponState=dependency}},require=function(m)assert(m==dependency);return WeaponState end},{__index=getfenv()}))
local tools=assert(loadstring(SIMULATION_SOURCE))()({Config=Config,Rules=Rules,WeaponState=WeaponState,
    Containment=Containment,MovementState=MovementState,WeaponSkins=WeaponSkins,RoundStats=RoundStats,LoadoutState=loadout(),CombatSource=COMBAT_SOURCE})
local checks=0
local function check(v,label)assert(v,label);checks+=1 end
local function start()
    local s=tools.simulation({roundSource=ROUND_SOURCE,startupSource=STARTUP_SOURCE,roundConfig=RoundConfig,
        roundRules=RoundRules,mapConfig=MapConfig,escapeConfig=EscapeConfig,escapeState=EscapeState,escapeSessionSource=SESSION_SOURCE,holdGatesSource=HOLD_GATES_SOURCE})
    local people={s.add('One','Humans'),s.add('Two','Humans'),s.add('Three','Humans')}
    s.advance(RoundConfig.Intermission+RoundConfig.Preparation+1)
    check(s.rs:GetAttribute('ZO_RoundState')=='Active' and s.rs:GetAttribute('ZO_RoundMode')=='Escape','production first round starts Escape')
    local human,zombie
    for _,p in people do if p.Team.Name=='Humans' then human=p else zombie=p end end
    local map=s.world:FindFirstChild(MapConfig.ModelName)
    local gate=map.R50_EvacuationBay.EvacuationGate
    check(gate.CanCollide and gate.CanQuery,'final gate begins closed')
    local function activate(i,actor)
        local part=map.EscapeObjectives:FindFirstChild('Control'..i)
        actor.Character.HumanoidRootPart.Position=part.Position
        actor.Character.Head.Position=part.Position+tools.Vector.yAxis*2
        part.Activate.Triggered:Fire(actor);s.advance(0)
    end
    return s,people,human,zombie,map,gate,activate
end
do
    local s,people,human,zombie,map,gate,activate=start()
    activate(2,human);check(s.rs:GetAttribute('ZO_EscapeStage')==1 and s.rs:GetAttribute('ZO_EscapeStatus')=='Ready','future trigger cannot skip sequence')
    activate(1,zombie);check(s.rs:GetAttribute('ZO_EscapeStatus')=='Ready','zombie cannot operate human objective')
    local outsider=s.add('Late','Humans');activate(1,outsider)
    check(outsider.Team.Name=='Lobby' and outsider.Character.Humanoid.WalkSpeed==0 and outsider.Character.Humanoid.JumpPower==0,'late spectator cannot move its body through the active fight')
    check(s.rs:GetAttribute('ZO_EscapeStatus')=='Ready','late spectator cannot operate an objective')
    local control=map.EscapeObjectives.Control1
    human.Character.HumanoidRootPart.Position=tools.Vector.zero;control.Activate.Triggered:Fire(human);s.advance(0)
    check(s.rs:GetAttribute('ZO_EscapeStatus')=='Ready','forged distant prompt activation is rejected')
    human.Character.HumanoidRootPart.Position=control.Position
    human.Character.Head.Position=control.Position+tools.Vector.yAxis*2
    s.ray(function()return {Instance=gate}end);control.Activate.Triggered:Fire(human);s.advance(0)
    check(s.rs:GetAttribute('ZO_EscapeStatus')=='Ready','blocked line of sight rejects prompt activation')
    s.ray(function()return nil end)
    for i,stage in EscapeConfig.Stages do
        activate(i,human);check(s.rs:GetAttribute('ZO_EscapeStatus')=='Holding','human starts a timed defense')
        local before=s.rs:GetAttribute('ZO_EscapeRemaining');activate(i,human)
        check(s.rs:GetAttribute('ZO_EscapeRemaining')==before,'repeated activation cannot extend hold')
        s.advance(stage.HoldSeconds+.3)
    end
    check(s.rs:GetAttribute('ZO_EscapeStatus')=='Extraction' and not gate.CanCollide,'all three objectives open the final gate')
    human.Character.HumanoidRootPart.Position=tools.Vector.new(228,4,226)
    local credit=human:GetAttribute('ZO_Credits')
    s.advance(EscapeConfig.ExtractionSeconds+.3)
    check(s.rs:GetAttribute('ZO_RoundState')=='Results' and s.rs:GetAttribute('ZO_LastWinner')=='Humans','actual Round awards extraction victory')
    check(human:GetAttribute('ZO_EscapedRound')==1 and human:GetAttribute('ZO_SurvivedRound')==1,'only extracted human receives reward eligibility')
    check(human:GetAttribute('ZO_Credits')==credit+Config.Economy.SurvivalReward,'Combat pays extraction reward exactly once')
    check(human:GetAttribute('ZO_SummaryObjectives')==3 and human:GetAttribute('ZO_SummaryRound')==1,'summary counts only the three accepted objective activations')
    check(human:GetAttribute('ZO_SummaryReward')==Config.Economy.SurvivalReward,'extraction bonus appears in confirmed round summary')
    for _,p in people do if p~=human then check(p:GetAttribute('ZO_SurvivedRound')==0,'players outside extraction cannot receive survival reward')end end
    check(s.rs:GetAttribute('ZO_LastEscaped')==1 and not gate.CanCollide,'result preserves escaped count and resets gate')
    check(outsider.Character.Humanoid.WalkSpeed>0 and outsider.Character.Humanoid.JumpPower>0,'result cleanup releases nonparticipant movement before next mode or training')
    local old=map.EscapeObjectives.Control1.Activate
    old.Triggered:Fire(human);s.advance(0)
    check(s.rs:GetAttribute('ZO_EscapeStage')==nil,'destroyed session disconnects old triggers')
    s.advance(RoundConfig.Results+RoundConfig.Intermission+RoundConfig.Preparation+1)
    check(s.rs:GetAttribute('ZO_RoundMode')=='Survival' and s.rs:GetAttribute('ZO_RoundState')=='Active','next round is original Survival')
end
do
    local s,_,human,_,_,gate=start()
    s.advance(EscapeConfig.Duration+1)
    check(s.rs:GetAttribute('ZO_LastWinner')=='Zombies','Escape timeout cannot use Survival timer victory')
    check(human:GetAttribute('ZO_SurvivedRound')==0 and not gate.CanCollide,'timeout rewards nobody and resets gate')
end
do
    local s,people,_,_,map,gate=start()
    s.remove(people[1]);s.remove(people[2]);s.advance(.4)
    check(s.rs:GetAttribute('ZO_LastWinner')=='Cancelled','disconnect below minimum cancels Escape')
    check(not gate.CanCollide and not map.EscapeObjectives.Control1.Activate.Enabled,'cancellation releases gate and prompts')
end
do
    local s,_,human,zombie,_,gate,activate=start()
    for i,stage in EscapeConfig.Stages do activate(i,human);s.advance(stage.HoldSeconds+.3) end
    zombie.Character.HumanoidRootPart.Position=tools.Vector.new(228,4,226)
    s.advance(EscapeConfig.ExtractionSeconds+.3)
    check(s.rs:GetAttribute('ZO_LastWinner')=='Zombies','zombie inside the bay cannot count as an evacuated human')
    check(human:GetAttribute('ZO_SurvivedRound')==0 and s.rs:GetAttribute('ZO_LastEscaped')==0,'living human outside bay is not a survivor')
    check(not gate.CanCollide,'failed extraction also resets the gate')
end
do
    local s,people,human,_,map,_,activate=start()
    local gate=map.EscapeHoldGates.GeneratorExit
    local params
    s.overlap(function(_,_,p)params=p;return {human.Character.HumanoidRootPart}end)
    activate(1,human)
    check(not gate.CanCollide and s.rs:GetAttribute('ZO_HoldGateStatus')=='Blocked','retention cannot close through a character or barricade')
    check(params.FilterType=='Include' and params.MaxParts==1 and table.find(params.FilterDescendantsInstances,s.props)~=nil,'clearance query includes physical props and limits overlap output')
    s.overlap(function()return{}end);s.advance(.3)
    check(gate.CanCollide and gate.CanQuery and gate.Lettering.Enabled,'clear passage closes and enables its warning')
    s.overlap(function()return {human.Character.HumanoidRootPart}end);s.advance(.3)
    check(gate.CanCollide,'touching an already closed retention cannot reopen it')
    s.advance(EscapeConfig.Stages[1].HoldSeconds+.3)
    check(not gate.CanCollide and not gate.Lettering.Enabled,'defense deadline opens and clears first retention')
    activate(2,human)
    check(not map.EscapeHoldGates.MaintenanceExit.CanCollide,'occupied maintenance exit also waits to close')
    s.overlap(function()return{}end);s.advance(.3)
    check(map.EscapeHoldGates.MaintenanceExit.CanCollide,'second retention closes once clear')
    s.remove(people[1]);s.remove(people[2]);s.advance(.4)
    check(not gate.CanCollide and not map.EscapeHoldGates.MaintenanceExit.CanCollide,'cancellation restores every retention collider')
end
do
    local s,_,_,zombie=start()
    zombie.Character.Humanoid:TakeDamage(1000);s.advance(0)
    local deadline=zombie:GetAttribute('ZO_RespawnAt')
    check(type(deadline)=='number' and math.abs(deadline-s.world:GetServerTimeNow()-RoundConfig.RespawnSeconds)<.01,'real death publishes a server-time respawn deadline')
    s.character(zombie);s.advance(0)
    check(zombie:GetAttribute('ZO_RespawnAt')==nil and zombie.Character.Humanoid.Health==RoundConfig.ZombieHealth,'new character clears deadline and restores infected role')
end
print(('PASS integrated Escape + combat + round: %d checks; API doubles, no engine execution'):format(checks))
