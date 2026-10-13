--!strict
-- Zombie Outbreak Reborn | Autoridade de rodada e infecção (servidor)
-- Survival inicial, sem armas. Mapas finais e o modo Escape usarão serviços separados.
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RoundConfig"))
local rng = Random.new()

local function ensureTeam(name: string, color: BrickColor): Team
    local team = Teams:FindFirstChild(name)
    if not team then
        team = Instance.new("Team")
        team.Name = name
        team.Parent = Teams
    end
    assert(team:IsA("Team"))
    team.TeamColor = color
    team.AutoAssignable = false
    return team
end

local lobby = ensureTeam("Lobby", BrickColor.new("Medium stone grey"))
local humans = ensureTeam("Humans", BrickColor.new("Bright blue"))
local zombies = ensureTeam("Zombies", BrickColor.new("Bright green"))

local world = Workspace:FindFirstChild("ZO_TestSpawns") :: Folder?
if not world then
    world = Instance.new("Folder")
    world.Name = "ZO_TestSpawns"
    world.Parent = Workspace
end

local function ensureSpawn(name: string, position: Vector3, color: Color3): BasePart
    local existing = world:FindFirstChild(name)
    if existing and existing:IsA("BasePart") then return existing end
    local part = Instance.new("Part")
    part.Name = name
    part.Size = Vector3.new(2, 0.2, 2)
    part.Position = position
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    part.Color = color
    part.Material = Enum.Material.Metal
    part.Parent = world
    return part
end
local humanSpawn = ensureSpawn("HumanSpawn", Vector3.new(-25, 3, -115), Color3.fromRGB(35, 100, 170))
local zombieSpawn = ensureSpawn("ZombieSpawn", Vector3.new(105, 3, -115), Color3.fromRGB(40, 115, 66))

local state = "Waiting"
local roundId = 0
local infectedThisRound: {[Player]: boolean} = {}
local initialSelection: {[Player]: boolean} = {}
local roundParticipants: {[Player]: boolean} = {}

local function setState(newState: string, remaining: number)
    state = newState
    ReplicatedStorage:SetAttribute("ZO_RoundState", state)
    ReplicatedStorage:SetAttribute("ZO_Remaining", remaining)
end

local function count(): (number, number)
    local h, z = 0, 0
    for player in pairs(roundParticipants) do
        if player.Parent == Players then
            if player.Team == humans then h += 1 end
            if player.Team == zombies then z += 1 end
        end
    end
    return h, z
end

local function updateCounts()
    local h, z = count()
    ReplicatedStorage:SetAttribute("ZO_Humans", h)
    ReplicatedStorage:SetAttribute("ZO_Zombies", z)
end

local function roleStyle(player: Player)
    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        if player.Team == zombies then
            humanoid.MaxHealth = Config.ZombieHealth
            humanoid.Health = Config.ZombieHealth
            humanoid.WalkSpeed = Config.ZombieWalkSpeed
        else
            humanoid.MaxHealth = Config.HumanHealth
            humanoid.Health = Config.HumanHealth
            humanoid.WalkSpeed = Config.HumanWalkSpeed
        end
    end
    local highlight = character:FindFirstChild("ZO_RoleHighlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "ZO_RoleHighlight"
        highlight.DepthMode = Enum.HighlightDepthMode.Occluded
        highlight.FillTransparency = 0.8
        highlight.OutlineTransparency = 0.25
        highlight.Parent = character
    end
    if highlight:IsA("Highlight") then
        highlight.FillColor = if player.Team == zombies then Color3.fromRGB(45, 165, 60) else Color3.fromRGB(50, 130, 220)
        highlight.OutlineColor = highlight.FillColor
        highlight.Enabled = player.Team ~= lobby
    end
end

local function teleport(player: Player, part: BasePart)
    local character = player.Character
    if not character then return end
    character:PivotTo(part.CFrame * CFrame.new(0, 5, 0))
end

local function setRole(player: Player, team: Team, move: boolean?)
    player.Team = team
    player.Neutral = false
    player:SetAttribute("ZO_Role", team.Name)
    roleStyle(player)
    if move then teleport(player, if team == zombies then zombieSpawn else humanSpawn) end
    updateCounts()
end

local function infect(player: Player)
    if state ~= "Active" or not roundParticipants[player] then return end
    if player.Team ~= humans or infectedThisRound[player] then return end
    infectedThisRound[player] = true
    setRole(player, zombies, false) -- mantém a posição onde houve infecção
end

local function onJoin(player: Player)
    setRole(player, lobby, false)
    player.CharacterAdded:Connect(function()
        task.defer(function()
            if player.Parent ~= Players then return end
            roleStyle(player)
            if state == "Active" and roundParticipants[player] then
                teleport(player, if player.Team == zombies then zombieSpawn else humanSpawn)
            elseif state ~= "Active" then
                teleport(player, humanSpawn)
            end
        end)
    end)
end

Players.PlayerAdded:Connect(onJoin)
for _, player in ipairs(Players:GetPlayers()) do onJoin(player) end
Players.PlayerRemoving:Connect(function(player)
    infectedThisRound[player] = nil
    initialSelection[player] = nil
    roundParticipants[player] = nil
    updateCounts()
end)

task.spawn(function()
    while true do
        task.wait(Config.InfectionPoll)
        if state ~= "Active" then continue end
        local attackers = {}
        local victims = {}
        for player in pairs(roundParticipants) do
            if player.Parent ~= Players then continue end
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then continue end
            if player.Team == zombies then
                table.insert(attackers, root)
            elseif player.Team == humans and not infectedThisRound[player] then
                table.insert(victims, {player = player, root = root})
            end
        end
        for _, victim in ipairs(victims) do
            for _, attacker in ipairs(attackers) do
                if (victim.root.Position - attacker.Position).Magnitude <= Config.InfectionDistance then
                    infect(victim.player)
                    break
                end
            end
        end
    end
end)

local function runCountdown(newState: string, seconds: number): boolean
    for remaining = seconds, 0, -1 do
        setState(newState, remaining)
        updateCounts()
        if #Players:GetPlayers() < Config.MinimumPlayers then return false end
        task.wait(1)
    end
    return true
end

setState("Waiting", 0)
updateCounts()
print("[Zombie Outbreak] Round system online")

while true do
    while #Players:GetPlayers() < Config.MinimumPlayers do
        setState("Waiting", 0)
        task.wait(1)
    end
    if not runCountdown("Intermission", Config.Intermission) then continue end
    local participants = Players:GetPlayers()
    roundParticipants = {}
    infectedThisRound = {}
    initialSelection = {}
    roundId += 1

    for _, player in ipairs(participants) do
        roundParticipants[player] = true
        setRole(player, humans, true)
    end

    local selectedCount = math.clamp(math.ceil(#participants * Config.InitialZombieRatio), 1, #participants - 1)
    -- Fisher-Yates para seleção sem repetição
    for i = #participants, 2, -1 do
        local j = rng:NextInteger(1, i)
        participants[i], participants[j] = participants[j], participants[i]
    end
    for i = 1, selectedCount do
        initialSelection[participants[i]] = true
    end

    if not runCountdown("Preparation", Config.Preparation) then
        for player in pairs(roundParticipants) do if player.Parent == Players then setRole(player, lobby) end end
        roundParticipants = {}
        updateCounts()
        continue
    end

    for player in pairs(initialSelection) do
        if player.Parent == Players and roundParticipants[player] then
            infectedThisRound[player] = true
            setRole(player, zombies, true)
        end
    end

    local result = "Humans"
    for remaining = Config.Duration, 0, -1 do
        setState("Active", remaining)
        updateCounts()
        local h, z = count()
        if h == 0 then
            result = "Zombies"
            break
        end
        if z == 0 or #Players:GetPlayers() < Config.MinimumPlayers then
            result = "Cancelled"
            break
        end
        task.wait(1)
    end

    ReplicatedStorage:SetAttribute("ZO_LastWinner", result)
    setState("Results", Config.Results)
    for player in pairs(roundParticipants) do
        if player.Parent == Players then setRole(player, lobby, false) end
    end
    roundParticipants = {}
    infectedThisRound = {}
    initialSelection = {}
    updateCounts()
    task.wait(Config.Results)
end
