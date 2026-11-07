-- All production authorities share a scheduler; rig/path/contact APIs are doubles.
local function load(source)return assert(loadstring(source))()end
local Config,Rules,WeaponState=load(CONFIG_SOURCE),load(RULES_SOURCE),load(WEAPON_SOURCE)
local Containment,MovementState=load(CONTAINMENT_SOURCE),load(MOVEMENT_STATE_SOURCE)
local WeaponSkins,RoundStats=load(WEAPON_SKINS_SOURCE),load(ROUND_STATS_SOURCE)
local RoundConfig,RoundRules,MapConfig=load(ROUND_CONFIG_SOURCE),load(ROUND_RULES_SOURCE),load(MAP_CONFIG_SOURCE)
local EscapeConfig,EscapeState=load(ESCAPE_CONFIG_SOURCE),load(ESCAPE_STATE_SOURCE)
local TrainingConfig,TrainingState=load(TRAINING_CONFIG_SOURCE),load(TRAINING_STATE_SOURCE)
local token={};local inventory=assert(loadstring(LOADOUT_SOURCE))
setfenv(inventory,setmetatable({script={Parent={WeaponState=token}},require=function(t)assert(t==token);return WeaponState end},{__index=getfenv()}))
local tools=load(SIMULATION_SOURCE)({Config=Config,Rules=Rules,WeaponState=WeaponState,Containment=Containment,
    MovementState=MovementState,WeaponSkins=WeaponSkins,RoundStats=RoundStats,LoadoutState=inventory(),CombatSource=COMBAT_SOURCE})
local checks=0
local function check(value,label)assert(value,label);checks+=1 end
local function start()
    local s=tools.simulation({roundSource=ROUND_SOURCE,startupSource=STARTUP_SOURCE,roundConfig=RoundConfig,
        roundRules=RoundRules,mapConfig=MapConfig,escapeConfig=EscapeConfig,escapeState=EscapeState,
        escapeSessionSource=SESSION_SOURCE,holdGatesSource=HOLD_GATES_SOURCE,trainingDirectorSource=TRAINING_SOURCE,
        trainingConfig=TrainingConfig,trainingState=TrainingState})
    local player=s.add('Solo','Lobby');s.advance(1)
    local map=s.world:FindFirstChild(MapConfig.ModelName)
    local function activate(i)
        local part=map.EscapeObjectives:FindFirstChild('Control'..i)
        player.Character:PivotTo({Position=part.Position})
        part.Activate.Triggered:Fire(player);s.advance(0)
    end
    return s,player,map,activate
end
do
    local s,p,map,activate=start()
    check(s.rs:GetAttribute('ZO_RoundState')=='Training'and s.rs:GetAttribute('ZO_TrainingMode')=='Escape','one player enters actual Escape exercise without fake multiplayer')
    check(s.rs:GetAttribute('ZO_TrainingStage')=='Intro'and p.Character.Pivot.Position.X==144 and not map.EscapeObjectives.Control1.Activate.Enabled,'first attempt starts near generator with short preparation and no misleading active prompt')
    activate(1);check(s.rs:GetAttribute('ZO_EscapeStatus')=='Ready','intro cannot prematurely trigger defense')
    s.advance(TrainingConfig.IntroSeconds+.5)
    check(s.rs:GetAttribute('ZO_TrainingStage')=='Fighting'and map.EscapeObjectives.Control1.Activate.Enabled,'same real objective becomes usable after intro')
    local targets=s.world:FindFirstChild('ZO_PracticeTargets')
    check(targets and #targets:GetChildren()>0,'pressure spawns actual server-owned NPC models during the exercise')
    local first=targets:GetChildren()[1]
    check(first.HumanoidRootPart.NetworkOwner==nil and first.Humanoid.LastMove~=nil,'NPC pursues through existing director path loop')
    -- Kill through real Combat, not directly through the training counter.
    local credits=p:GetAttribute('ZO_Credits')
    s.ray(function()return{Instance=first.Head,Position=first.Head.Position,Normal=tools.Vector.yAxis}end)
    for _=1,6 do s.fire(p);s.advance(.12)end
    s.ray(function()return nil end)
    check(s.rs:GetAttribute('ZO_TrainingKills')==1 and p:GetAttribute('ZO_Credits')==credits+Config.Economy.TrainingKillReward,'accepted combat kill pays training reward and advances exercise tally')
    check((p:GetAttribute('ZO_SummaryRound')or 0)==0,'solo kills cannot fabricate a multiplayer result')
    activate(2);check(s.rs:GetAttribute('ZO_EscapeStage')==1,'solo exercise also rejects skipping objectives')
    for i,stage in EscapeConfig.Stages do
        activate(i);check(s.rs:GetAttribute('ZO_EscapeStatus')=='Holding','solo uses the actual timed defense')
        s.advance(stage.HoldSeconds+.3)
    end
    check(s.rs:GetAttribute('ZO_EscapeStatus')=='Extraction'and not map.R50_EvacuationBay.EvacuationGate.CanCollide,'all real holds open terminal in solo')
    p.Character:PivotTo({Position=tools.Vector.new(228,4,226)})
    s.advance(EscapeConfig.ExtractionSeconds+.3)
    check(s.rs:GetAttribute('ZO_TrainingStage')=='Won'and s.rs:GetAttribute('ZO_TrainingOutcome')=='Extracted','only actual extraction finishes exercise as a win')
    check(s.rs:GetAttribute('ZO_TrainingObjectives')==3,'result preserves three accepted panels')
    check(not s.world:FindFirstChild('ZO_PracticeTargets')and s.rs:GetAttribute('ZO_EscapeStatus')==nil,'win removes attackers and restores shared objectives')
    check(s.rs:GetAttribute('ZO_RoundId')==0 and p:GetAttribute('ZO_SurvivedRound')==0,'exercise does not consume multiplayer rotation or survival rewards')
    s.advance(TrainingConfig.ResultSeconds+.5)
    check(s.rs:GetAttribute('ZO_TrainingStage')=='Intro'and s.rs:GetAttribute('ZO_EscapeStage')==1,'result restarts full exercise with fresh controls')
end
do
    local s,p,map,activate=start();s.advance(6);activate(1)
    local second=s.add('Second','Lobby');s.advance(.5)
    check(not s.world:FindFirstChild('ZO_PracticeTargets')and s.world:GetAttribute('ZO_BarricadePractice')==false,'second connection removes solo actors and capabilities')
    check(s.rs:GetAttribute('ZO_TrainingMode')==nil and s.rs:GetAttribute('ZO_EscapeStatus')==nil,'handoff destroys exercise and all shared escape state')
    check(not map.EscapeHoldGates.GeneratorExit.CanCollide,'handoff cannot leave a retention locked')
    s.advance(RoundConfig.Intermission+RoundConfig.Preparation+1)
    check(s.rs:GetAttribute('ZO_RoundState')=='Active'and s.rs:GetAttribute('ZO_RoundMode')=='Escape'and s.rs:GetAttribute('ZO_RoundId')==1,'normal player infection match remains first real Escape round')
    check(p.Team.Name~=second.Team.Name and not s.world:FindFirstChild('ZO_PracticeTargets'),'multiplayer uses player roles and contains no training NPCs')
end
do
    local s,p,map,activate=start();s.advance(6);activate(1)
    p.Character.Humanoid.Health=0;s.advance(.4)
    check(s.rs:GetAttribute('ZO_TrainingStage')=='Lost'and s.rs:GetAttribute('ZO_TrainingOutcome')=='Eliminated','player death ends exercise with visible retry')
    check(not map.EscapeHoldGates.GeneratorExit.CanCollide and not s.world:FindFirstChild('ZO_PracticeTargets'),'death releases retained passage and actors')
    s.character(p);s.advance(TrainingConfig.ResultSeconds+.5)
    check(s.rs:GetAttribute('ZO_TrainingStage')=='Intro','respawn cannot get stuck in dead exercise')
end
do
    local s,_,map=start();s.advance(EscapeConfig.Duration+TrainingConfig.IntroSeconds+1)
    check(s.rs:GetAttribute('ZO_TrainingStage')=='Lost'and s.rs:GetAttribute('ZO_TrainingOutcome')=='ExtractionFailed','waiting without extracting cannot win an Escape exercise')
    check(not map.R50_EvacuationBay.EvacuationGate.CanCollide,'timeout restores terminal')
end
do
    local s,p= start();s.advance(7)
    local old=s.world:FindFirstChild('ZO_PracticeTargets'):GetChildren()
    p.Character:PivotTo({Position=tools.Vector.new(-220,-20,-100)})
    s.advance(4)
    for _,bot in old do check(bot.Parent==nil,'actors left far behind are retired without a combat kill')end
    check(s.rs:GetAttribute('ZO_TrainingKills')==0,'retiring distant actors grants no free kills')
end
do
    local s,_,_=start()
    local blocker=s.instance('Part','Occupied',s.world);blocker.CanCollide=true
    s.overlap(function()return{blocker}end);s.advance(7)
    local targets=s.world:FindFirstChild('ZO_PracticeTargets')
    check(#targets:GetChildren()==0,'all occupied pressure candidates create no overlapping actors')
    s.overlap(function()return{}end);s.advance(.5)
    check(#targets:GetChildren()>0,'clearing a candidate resumes pressure without consuming a finite-wave slot')
    s.advance(20)
    check(#targets:GetChildren()<=TrainingConfig.Escape.MaxAlive,'continuous exercise pressure is still capped')
end
do
    local s,p,map,activate=start();s.advance(6)
    for i,stage in EscapeConfig.Stages do activate(i);s.advance(stage.HoldSeconds+.3)end
    p.Character:PivotTo({Position=tools.Vector.new(170,4,254)});s.advance(EscapeConfig.ExtractionSeconds+.3)
    check(s.rs:GetAttribute('ZO_TrainingStage')=='Lost','opening the terminal without entering it cannot win practice')
    check(s.rs:GetAttribute('ZO_TrainingOutcome')=='ExtractionFailed','missed extraction is explicitly distinguished from death')
end
print(('PASS actual solo Escape + Round/Combat/Session: %d checks; API doubles, not engine play'):format(checks))
