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

local function alive(model: Model?): boolean
    local hum=model and model:FindFirstChildOfClass("Humanoid")
    return hum~=nil and hum.Health>0
end
local function characterReady(player: Player): boolean
    local char=player.Character
    local root=char and char:FindFirstChild("HumanoidRootPart")
    return player.Parent==Players and alive(char) and root~=nil and root:IsA("BasePart")
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
        hum.WalkSpeed=if player.Team==zombies then Config.ZombieWalkSpeed else Config.HumanWalkSpeed
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
local function setRole(player: Player,team: Team,move: boolean?)
    player.Team=team;player.Neutral=false;player:SetAttribute("ZO_Role",team.Name)
    style(player)
    if move then teleport(player,if team==zombies then zombieSpawn else humanSpawn) end
    updateCounts()
end
local function join(player: Player)
    setRole(player,lobby)
    local function characterAdded(char: Model)
        local root=char:WaitForChild("HumanoidRootPart",10)
        local hum=char:WaitForChild("Humanoid",10)
        if not root or not hum or not hum:IsA("Humanoid") or player.Character~=char or player.Parent~=Players then return end
        hum.Died:Connect(function()
            if player.Character~=char or state~="Active" or not participants[player] then return end
            if player.Team==humans then setRole(player,zombies) end
            -- Zombies retain their role while waiting for Roblox character respawn.
        end)
        style(player)
        if participants[player] and (state=="Preparation" or state=="Active") then
            teleport(player,if player.Team==zombies then zombieSpawn else humanSpawn)
        else teleport(player,lobbySpawn) end
    end
    player.CharacterAdded:Connect(characterAdded)
    if player.Character then task.spawn(characterAdded,player.Character) end
end
Players.PlayerAdded:Connect(join)
for _,player in Players:GetPlayers() do join(player) end
Players.PlayerRemoving:Connect(function(player)
    participants[player]=nil;previousMothers[player]=nil;updateCounts()
end)
Players.RespawnTime=Config.RespawnSeconds

infection.OnInvoke=function(attacker: Player,target: Model): boolean
    if typeof(attacker)~="Instance" or not attacker:IsA("Player") or typeof(target)~="Instance" or not target:IsA("Model") then return false end
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
    RS:SetAttribute("ZO_LastWinner",winner)
    setState("Results",Config.Results)
    for player in participants do if player.Parent==Players then setRole(player,lobby) end end
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
        setState("Waiting",0);task.wait(.5)
    end
    RS:SetAttribute("ZO_WaitingReason","")
    if not countdown("Intermission",Config.Intermission) then continue end
    participants={};roundId+=1;RS:SetAttribute("ZO_RoundId",roundId)
    workspace:SetAttribute("ZO_BarricadePractice",false)
    local practice=workspace:FindFirstChild("ZO_PracticeTargets")
    if practice then practice:Destroy() end
    for _,player in Players:GetPlayers() do
        if characterReady(player) then participants[player]=true;setRole(player,humans,true) end
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
        setRole(player,zombies,Config.MotherZombieTeleport)
    end
    local deadline=os.clock()+Config.Duration
    local result=nil
    repeat
        health()
        local remaining=math.max(0,math.ceil(deadline-os.clock()))
        setState("Active",remaining)
        local h,z=counts()
        result=RoundRules.result(h,z,h+z,Config.MinimumPlayers,remaining)
        if not result then task.wait(.25) end
    until result~=nil
    cleanup(result :: string)
end
end
local ok,message=xpcall(main,debug.traceback)
if not ok then fail(tostring(message)) end
