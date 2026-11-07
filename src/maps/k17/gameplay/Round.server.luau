--!strict
-- K-17 classic Survival authority. No proximity infection task exists in this profile.
local Players=game:GetService("Players")
local Teams=game:GetService("Teams")
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerStorage")
local RunService=game:GetService("RunService")
local function fail(message: string)
    RS:SetAttribute("ZO_GameplayRoundReady",false)
    RS:SetAttribute("ZO_GameplayStatus","Error")
    RS:SetAttribute("ZO_GameplayError",("ZombieRound: "..message):sub(1,1500))
    RS:SetAttribute("ZO_RoundState","Error")
    warn("[K17] Round stopped: "..message)
end
local function main()
RS:SetAttribute("ZO_GameplayRoundReady",false)
RS:SetAttribute("ZO_RoundState","Starting")
local function step(message: string) RS:SetAttribute("ZO_StartupStep",message) end
local function dependency(parent: Instance,name: string,class: string?): Instance
    step("Carregando "..name)
    local child=parent:WaitForChild(name,12)
    assert(child,"Dependência ausente: "..parent.Name.."/"..name.." (12s)")
    assert(not class or child:IsA(class),"Classe inválida: "..parent.Name.."/"..name)
    return child
end
local shared=dependency(RS,"Shared","Folder")
local gameplay=dependency(RS,"K17Gameplay","Folder")
local Config=require(dependency(shared,"RoundConfig","ModuleScript"))
local MapConfig=require(dependency(shared,"MapConfig","ModuleScript"))
local RoundRules=require(dependency(gameplay,"RoundRules","ModuleScript"))
local Rules=require(dependency(gameplay,"Rules","ModuleScript"))
local MovementState=require(dependency(gameplay,"MovementState","ModuleScript"))
RS:SetAttribute("ZO_MinimumPlayers",Config.MinimumPlayers)
local rng=Random.new()
local function ensureTeam(name: string,color: string): Team
    local team=Teams:FindFirstChild(name)
    if not team then team=Instance.new("Team");team.Name=name;team.Parent=Teams end
    assert(team:IsA("Team"));team.TeamColor=BrickColor.new(color);team.AutoAssignable=false
    return team
end
local lobby=ensureTeam("Lobby","Medium stone grey")
local humans=ensureTeam("Humans","Bright blue")
local zombies=ensureTeam("Zombies","Bright green")
local world=dependency(workspace,MapConfig.ModelName,"Model")
local spawns=dependency(world,"Spawns","Model")
local humanSpawn=dependency(spawns,MapConfig.HumanSpawn,"BasePart") :: BasePart
local zombieSpawn=dependency(spawns,MapConfig.ZombieSpawn,"BasePart") :: BasePart
local lobbySpawn=dependency(spawns,MapConfig.LobbySpawn,"BasePart") :: BasePart
local infection=dependency(dependency(SS,"ZO_Gameplay","Folder"),"Infect","BindableFunction") :: BindableFunction
local state="Waiting"
local roundId=0
local participants: {[Player]: boolean}={}
local previousMothers: {[Player]: boolean}={}
local characterCleanups: {[Player]: () -> ()}={}
local mode="Survival"
local escape: any=nil
local escapeConfig: any=nil
local pendingSpawns: {[Player]: any}={}
RS:SetAttribute("ZO_RoundMode",mode)

local function alive(model: Model?): boolean
    local hum=model and model:FindFirstChildOfClass("Humanoid")
    return hum~=nil and hum.Health>0
end
local function characterReady(player: Player): boolean
    local char=player.Character
    local root=char and char:FindFirstChild("HumanoidRootPart")
    return player.Parent==Players and char~=nil and char:IsDescendantOf(workspace)
        and alive(char) and root~=nil and root:IsA("BasePart")
end
local function readyCount(): number
    local ready=0
    for _,player in Players:GetPlayers() do if characterReady(player) then ready+=1 end end
    RS:SetAttribute("ZO_ReadyPlayers",ready)
    RS:SetAttribute("ZO_ConnectedPlayers",#Players:GetPlayers())
    return ready
end
local function health()
    assert(RS:GetAttribute("ZO_GameplayStatus")~="Error",RS:GetAttribute("ZO_GameplayError") or "Falha em outro controlador")
end
local function counts(): (number,number)
    local h,z=0,0
    for player in participants do
        if player.Parent~=Players then continue end
        if player.Team==humans then h+=1 elseif player.Team==zombies then z+=1 end
    end
    return h,z
end
local function updateCounts()
    local h,z=counts();RS:SetAttribute("ZO_Humans",h);RS:SetAttribute("ZO_Zombies",z)
end
local function setState(value: string,remaining: number)
    state=value;RS:SetAttribute("ZO_RoundState",state);RS:SetAttribute("ZO_Remaining",remaining)
    updateCounts()
end
local function style(player: Player)
    local char=player.Character
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health>0 then
        hum.MaxHealth=if player.Team==zombies then Config.ZombieHealth else Config.HumanHealth
        hum.Health=hum.MaxHealth
        local observing=player.Team==lobby and (state=="Active" or state=="Preparation")
        if observing then
            if hum:GetAttribute("ZO_LobbyJumpPower")==nil then
                hum:SetAttribute("ZO_LobbyJumpPower",if typeof(hum.JumpPower)=="number" then hum.JumpPower else 50)
                hum:SetAttribute("ZO_LobbyJumpHeight",if typeof(hum.JumpHeight)=="number" then hum.JumpHeight else 7.2)
            end
            hum.JumpPower=0;hum.JumpHeight=0;hum.Jump=false
        elseif hum:GetAttribute("ZO_LobbyJumpPower")~=nil then
            hum.JumpPower=hum:GetAttribute("ZO_LobbyJumpPower");hum.JumpHeight=hum:GetAttribute("ZO_LobbyJumpHeight")
            hum:SetAttribute("ZO_LobbyJumpPower",nil);hum:SetAttribute("ZO_LobbyJumpHeight",nil)
        end
        MovementState.setBase(hum,if observing then 0 elseif player.Team==zombies then Config.ZombieWalkSpeed else Config.HumanWalkSpeed,os.clock())
    end
    -- Remove the old full-body team glow; role is represented by HUD and character tint.
    local old=char and char:FindFirstChild("ZO_RoleHighlight")
    if old then old:Destroy() end
    if char then
        for _,part in char:GetChildren() do
            if part:IsA("BasePart") and part.Name~="HumanoidRootPart" then
                if part:GetAttribute("ZO_OriginalColor")==nil then part:SetAttribute("ZO_OriginalColor",part.Color) end
                part.Color=if player.Team==zombies then Color3.fromRGB(112,130,104) else part:GetAttribute("ZO_OriginalColor") :: Color3
            end
        end
    end
end
local function teleport(player: Player,marker: BasePart)
    if player.Character and alive(player.Character) then player.Character:PivotTo(marker.CFrame*CFrame.new(0,4,0)) end
end
local function clearPendingSpawn(player: Player)
    local pending=pendingSpawns[player]
    if pending then
        if pending.root.Parent then pending.root.Anchored=pending.anchored end
        pending.shield:Destroy();pendingSpawns[player]=nil
    end
    player:SetAttribute("ZO_SpawnPending",nil)
end
local function teleportZombie(player: Player)
    local char=player.Character
    if not char or not alive(char) then return end
    if mode~="Escape" or not escape then clearPendingSpawn(player);teleport(player,zombieSpawn);return end
    local root=char:FindFirstChild("HumanoidRootPart") :: BasePart
    if not root then return end
    local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances={char};params.MaxParts=0
    local point,group=escape:spawn(function(p)
        local parts=workspace:GetPartBoundsInBox(CFrame.new(p[1],p[2]+4,p[3]),Vector3.new(3.5,7,3.5),params)
        for _,part in parts do if part.CanCollide then return false end end
        return true
    end)
    if point then
        clearPendingSpawn(player)
        char:PivotTo(CFrame.new(point[1],point[2]+4,point[3]))
        root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
        player:SetAttribute("ZO_SpawnSector",if group>0 then escapeConfig.Respawns[group].Label else "Administração norte")
        player:SetAttribute("ZO_RespawnAt",nil)
    elseif not pendingSpawns[player] then
        -- All authored sites are occupied or close to humans: wait at the
        -- lobby, protected and unable to attack, rather than overlapping them.
        local shield=Instance.new("ForceField");shield.Name="ZO_SpawnWait";shield.Visible=false;shield.Parent=char
        pendingSpawns[player]={root=root,anchored=root.Anchored,shield=shield,retryAt=os.clock()+.5}
        teleport(player,lobbySpawn);root.Anchored=true
        player:SetAttribute("ZO_SpawnPending",true)
    end
end
local function setRole(player: Player,team: Team,move: boolean?)
    player.Team=team;player.Neutral=false;player:SetAttribute("ZO_Role",team.Name)
    style(player)
    if move then
        if team==zombies then teleportZombie(player) else teleport(player,humanSpawn) end
    end
    updateCounts()
end
local function join(player: Player)
    player:SetAttribute("ZO_SurvivedRound",0)
    player:SetAttribute("ZO_EscapedRound",0)
    setRole(player,lobby)
    local currentCharacter: Model?=nil
    local boundHumanoid: Humanoid?=nil
    local diedConnection: RBXScriptConnection?=nil
    local characterConnections: {RBXScriptConnection}={}
    local placed=false
    local function clearCharacter()
        clearPendingSpawn(player)
        for _,connection in characterConnections do connection:Disconnect() end
        table.clear(characterConnections)
        if diedConnection then diedConnection:Disconnect();diedConnection=nil end
        boundHumanoid=nil;currentCharacter=nil;placed=false
    end
    characterCleanups[player]=clearCharacter
    local function characterAdded(char: Model)
        if player.Character~=char or player.Parent~=Players then return end
        clearCharacter();currentCharacter=char
        local function refreshCharacter()
            if currentCharacter~=char or player.Character~=char or player.Parent~=Players
                or not char:IsDescendantOf(workspace) then return end
            local hum=char:FindFirstChildOfClass("Humanoid")
            if hum~=boundHumanoid then
                if diedConnection then diedConnection:Disconnect();diedConnection=nil end
                boundHumanoid=hum;placed=false
                if hum then
                    -- Bind death independently of the root arriving. A character
                    -- loading longer than 10s must not enter rounds without this.
                    diedConnection=hum.Died:Connect(function()
                        if currentCharacter~=char or player.Character~=char or boundHumanoid~=hum
                            or state~="Active" or not participants[player] then return end
                        player:SetAttribute("ZO_RespawnAt",workspace:GetServerTimeNow()+Config.RespawnSeconds)
                        if player.Team==humans then setRole(player,zombies) end
                        -- Zombies retain their role until Roblox respawns them.
                    end)
                end
            end
            local root=char:FindFirstChild("HumanoidRootPart")
            if placed or not hum or hum.Health<=0 or not root or not root:IsA("BasePart") then return end
            placed=true;style(player);player:SetAttribute("ZO_RespawnAt",nil)
            if participants[player] and (state=="Preparation" or state=="Active") then
                if player.Team==zombies then teleportZombie(player) else teleport(player,humanSpawn) end
            else teleport(player,lobbySpawn) end
        end
        table.insert(characterConnections,char.ChildAdded:Connect(function(child)
            if child:IsA("Humanoid") or child.Name=="HumanoidRootPart" then refreshCharacter() end
        end))
        table.insert(characterConnections,char.ChildRemoved:Connect(function(child)
            if child==boundHumanoid or child.Name=="HumanoidRootPart" then placed=false;refreshCharacter() end
        end))
        table.insert(characterConnections,char.AncestryChanged:Connect(refreshCharacter))
        refreshCharacter()
    end
    player.CharacterAdded:Connect(characterAdded)
    player.CharacterRemoving:Connect(function(char)
        if currentCharacter==char then clearCharacter() end
    end)
    if player.Character then task.spawn(characterAdded,player.Character) end
end
Players.PlayerAdded:Connect(join)
for _,player in Players:GetPlayers() do join(player) end
Players.PlayerRemoving:Connect(function(player)
    clearPendingSpawn(player)
    local cleanupCharacter=characterCleanups[player]
    if cleanupCharacter then cleanupCharacter();characterCleanups[player]=nil end
    participants[player]=nil;previousMothers[player]=nil;updateCounts()
end)
Players.RespawnTime=Config.RespawnSeconds

infection.OnInvoke=function(attacker: Player,target: Model): boolean
    if typeof(attacker)~="Instance" or not attacker:IsA("Player") or typeof(target)~="Instance" or not target:IsA("Model") then return false end
    if attacker:GetAttribute("ZO_SpawnPending")==true then return false end
    local victim=Players:GetPlayerFromCharacter(target)
    if victim then
        if victim==attacker or victim.Character~=target then return false end
        if not RoundRules.canInfect(state,attacker.Team and attacker.Team.Name,victim.Team and victim.Team.Name,
            participants[attacker]==true,participants[victim]==true,alive(attacker.Character),alive(target)) then return false end
        setRole(victim,zombies)
        victim:SetAttribute("ZO_InfectedBy",attacker.UserId)
        return true
    end
    -- Training dummies are accepted only in explicitly enabled, solo Studio practice.
    local phase=Rules.phase(state,RunService:IsStudio(),workspace:GetAttribute("ZO_BarricadePractice")==true,#Players:GetPlayers())
    local practice=workspace:FindFirstChild("ZO_PracticeTargets")
    if phase~="Active" or state~="Waiting" or not practice or not target:IsDescendantOf(practice)
        or target:GetAttribute("ZO_PracticeRole")~="Humans" or not alive(target) or not alive(attacker.Character)
        or attacker.Team~=zombies then return false end
    target:SetAttribute("ZO_PracticeRole","Zombies")
    local hum=target:FindFirstChildOfClass("Humanoid") :: Humanoid
    hum.MaxHealth=Config.ZombieHealth;hum.Health=hum.MaxHealth
    hum.DisplayName="Alvo infectado"
    for _,part in target:GetChildren() do
        if part:IsA("BasePart") and part.Name~="HumanoidRootPart" then part.Color=Color3.fromRGB(112,130,104) end
    end
    return true
end

local function countdown(value: string,seconds: number): boolean
    -- Deadline-based: a configured 35-second phase lasts 35 seconds, not 36.
    local deadline=os.clock()+seconds
    while true do
        health()
        local remaining=math.max(0,math.ceil(deadline-os.clock()))
        setState(value,remaining)
        if #Players:GetPlayers()<Config.MinimumPlayers or (value=="Intermission" and readyCount()<Config.MinimumPlayers) then return false end
        if remaining==0 then return true end
        task.wait(math.min(.25,math.max(.01,deadline-os.clock())))
    end
end
local function cleanup(winner: string)
    for player in pendingSpawns do clearPendingSpawn(player) end
    for _,player in Players:GetPlayers() do player:SetAttribute("ZO_SpawnSector",nil) end
    -- Snapshot eligibility before Results/Lobby signals. Economy must not infer
    -- survival from a delayed Team event after infection, death or round cleanup.
    for player in participants do
        if player.Parent==Players then
            local survived=winner=="Humans" and player.Team==humans and alive(player.Character)
                and (mode~="Escape" or (escape and escape.escaped[player]==true))
            player:SetAttribute("ZO_SurvivedRound",if survived then roundId else 0)
            player:SetAttribute("ZO_EscapedRound",if survived and mode=="Escape" then roundId else 0)
            player:SetAttribute("ZO_ResultRound",roundId);player:SetAttribute("ZO_ResultRole",if player.Team then player.Team.Name else "Lobby")
        end
    end
    local escaped=0
    if escape then
        for _ in escape.escaped do escaped+=1 end
        escape:destroy();escape=nil
    end
    RS:SetAttribute("ZO_LastEscaped",escaped)
    RS:SetAttribute("ZO_LastWinner",winner)
    setState("Results",Config.Results)
    for player in participants do if player.Parent==Players then setRole(player,lobby) end end
    -- Late spectators are not participants; release their observer movement
    -- restriction too before Waiting/solo training can take over.
    for _,player in Players:GetPlayers() do if not participants[player] then style(player) end end
    participants={};updateCounts()
    local deadline=os.clock()+Config.Results
    while os.clock()<deadline do
        RS:SetAttribute("ZO_Remaining",math.max(0,math.ceil(deadline-os.clock())))
        task.wait(.25)
    end
end
step("Aguardando controlador de combate")
local startupDeadline=os.clock()+20
while RS:GetAttribute("ZO_GameplayCombatReady")~=true do
    health()
    assert(os.clock()<startupDeadline,"Combat não iniciou em 20s; confira Output do servidor")
    task.wait(.1)
end
step("Controladores prontos")
setState("Waiting",0)
RS:SetAttribute("ZO_GameplayRoundReady",true)
while true do
    health()
    while readyCount()<Config.MinimumPlayers do
        health()
        RS:SetAttribute("ZO_WaitingReason",if #Players:GetPlayers()<Config.MinimumPlayers then "Players" else "Characters")
        setState(if Config.SoloTraining==true and #Players:GetPlayers()==1
            then "Training" else "Waiting",0);task.wait(.5)
    end
    RS:SetAttribute("ZO_WaitingReason","")
    if not countdown("Intermission",Config.Intermission) then continue end
    participants={};roundId+=1;RS:SetAttribute("ZO_RoundId",roundId)
    RS:SetAttribute("ZO_SummaryRound",0);RS:SetAttribute("ZO_MVPName","")
    mode=RoundRules.mode(Config.ModeRotation,roundId)
    RS:SetAttribute("ZO_RoundMode",mode)
    workspace:SetAttribute("ZO_BarricadePractice",false)
    local practice=workspace:FindFirstChild("ZO_PracticeTargets")
    if practice then practice:Destroy() end
    for _,player in Players:GetPlayers() do
        if characterReady(player) then
            participants[player]=true;player:SetAttribute("ZO_SurvivedRound",0);player:SetAttribute("ZO_EscapedRound",0)
            player:SetAttribute("ZO_RoundObjectives",0);setRole(player,humans,true)
        end
    end
    if mode=="Escape" then
        escapeConfig=require(dependency(gameplay,"EscapeConfig","ModuleScript"))
        local policy=require(dependency(gameplay,"EscapeState","ModuleScript"))
        local session=require(dependency(script.Parent,"EscapeSession","ModuleScript"))
        escape=session.new(world,RS,escapeConfig,policy,function(player)
            return state=="Active" and participants[player]==true and player.Parent==Players
                and player.Team==humans and characterReady(player)
        end,participants)
    end
    if not countdown("Preparation",Config.Preparation) then cleanup("Cancelled");continue end
    local eligible={}
    for player in participants do
        if player.Parent==Players and player.Team==humans and alive(player.Character) then table.insert(eligible,player) end
    end
    if #eligible<Config.MinimumPlayers then cleanup("Cancelled");continue end
    local mothers=RoundRules.choose(eligible,previousMothers,RoundRules.motherCount(#eligible,Config.InitialZombieRatio),function(i) return rng:NextInteger(1,i) end)
    previousMothers={}
    for _,player in mothers do
        previousMothers[player]=true
        setRole(player,zombies,if mode=="Escape" then true else Config.MotherZombieTeleport)
    end
    local deadline=os.clock()+(if mode=="Escape" then escapeConfig.Duration else Config.Duration)
    local result=nil
    repeat
        health()
        local remaining=math.max(0,math.ceil(deadline-os.clock()))
        setState("Active",remaining)
        for player,pending in pendingSpawns do
            if not participants[player] or player.Parent~=Players or player.Team~=zombies or not characterReady(player) then clearPendingSpawn(player)
            elseif os.clock()>=pending.retryAt then
                pending.retryAt=os.clock()+.5;teleportZombie(player)
            end
        end
        local h,z=counts()
        if mode=="Escape" then
            result=if h+z<Config.MinimumPlayers then "Cancelled" elseif h==0 then "Zombies" elseif z==0 then "Cancelled" else nil
            if not result then result=escape:update(os.clock(),remaining) end
        else result=RoundRules.result(h,z,h+z,Config.MinimumPlayers,remaining) end
        if not result then task.wait(.25) end
    until result~=nil
    if escape and escape.state.status=="Done" then
        -- ZE finale: only living humans in the extraction bay are protected.
        RS:SetAttribute("ZO_DecontaminationRound",roundId)
        for player in participants do
            if not escape.escaped[player] and alive(player.Character) then
                local hum=player.Character:FindFirstChildOfClass("Humanoid") :: Humanoid
                hum.Health=0
            end
        end
    end
    cleanup(result :: string)
end
end
local ok,message=xpcall(main,debug.traceback)
if not ok then fail(tostring(message)) end
