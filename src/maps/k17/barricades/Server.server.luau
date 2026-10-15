--!strict
-- Reservation/preview/commit: props stay solid and damageable until a valid placement.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local shared = RS:WaitForChild("K17Barricades")
local Config = require(shared:WaitForChild("Config"))
local Rules = require(shared:WaitForChild("Rules"))
local Placement = require(shared:WaitForChild("Placement"))
local RoundConfig = require(RS:WaitForChild("Shared"):WaitForChild("RoundConfig"))
local map = workspace:WaitForChild("ZO_K17Foundry")
local folder = workspace:WaitForChild("ZO_Barricades")
local remote = Instance.new("RemoteEvent")
remote.Name = "ZO_BarricadeAction"
remote.Parent = RS

type Entry = {model: Model, hull: BasePart, kind: any, home: CFrame, health: number, holder: Player?}
local entries: {[Model]: Entry} = {}
local selected: {[Player]: Entry} = {}
local expires: {[Player]: number} = {}
local requests: {[Player]: number} = {}
local attacks: {[Player]: number} = {}
local release: (Player, string?) -> ()

local function phase(): string?
    return Rules.phase(RS:GetAttribute("ZO_RoundState"),RunService:IsStudio(),workspace:GetAttribute("ZO_BarricadePractice")==true,#Players:GetPlayers())
end

local function characterInfo(player: Player): (Model?, BasePart?, BasePart?, Humanoid?)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local head = char and char:FindFirstChild("Head")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not root or not root:IsA("BasePart") or not head or not head:IsA("BasePart") or not hum or hum.Health<=0 then
        return nil,nil,nil,nil
    end
    return char,root,head,hum
end

local function role(player: Player): string?
    return if player.Team then player.Team.Name else nil
end

local function message(player: Player, value: string)
    remote:FireClient(player,"Message",value)
end

release = function(player: Player, reason: string?)
    local entry = selected[player]
    if not entry then return end
    selected[player],expires[player] = nil,nil
    entry.holder = nil
    entry.model:SetAttribute("ZO_Holder",nil)
    player:SetAttribute("ZO_BarricadeSelection",nil)
    local _,_,_,hum = characterInfo(player)
    if hum then hum.WalkSpeed = if role(player)=="Zombies" then RoundConfig.ZombieWalkSpeed else RoundConfig.HumanWalkSpeed end
    remote:FireClient(player,"Released",reason or "Seleção cancelada.")
end

local function lineOfSight(char: Model, head: BasePart, entry: Entry): boolean
    local point = Placement.closest(entry.hull,head.Position)
    local delta = point-head.Position
    if delta.Magnitude<.05 then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char}
    local hit = workspace:Raycast(head.Position,delta.Unit*(delta.Magnitude+.15),params)
    return hit~=nil and hit.Instance:IsDescendantOf(entry.model)
end

local function setHealth(entry: Entry, health: number)
    entry.health = health
    entry.model:SetAttribute("ZO_Health",health)
    if health<=0 then
        if entry.holder then release(entry.holder,"O zumbi destruiu o objeto.") end
        -- Keep the catalog/home for next round; remove collision and queries immediately.
        for _, part in entry.model:GetDescendants() do
            if part:IsA("BasePart") then
                part.CanCollide=false;part.CanQuery=false;part.Transparency=1
            end
        end
        entry.model:SetAttribute("ZO_Destroyed",true)
    end
end

local templates: {[Model]: Model} = {}
for name, prop in Config.Props do
    local model = folder:WaitForChild(name)
    assert(model:IsA("Model"))
    local hull = model:WaitForChild("Hull")
    assert(hull:IsA("BasePart"))
    local kind = Config.Kinds[prop.Kind]
    assert((hull.Size-Vector3.new(kind.Width,kind.Height,kind.Depth)).Magnitude<.01,"Hull/catalog mismatch: "..name)
    assert((hull.Position-Vector3.new(prop.X,Config.Zone.Floor+kind.Height/2,prop.Z)).Magnitude<.01,"Home/catalog mismatch: "..name)
    model.PrimaryPart = hull
    model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
    model:SetAttribute("ZO_Kind",prop.Kind)
    model:SetAttribute("ZO_Label",kind.Label)
    model:SetAttribute("ZO_MaxHealth",kind.Health)
    model:SetAttribute("ZO_Quarter",0)
    model:SetAttribute("ZO_Destroyed",false)
    local entry: Entry = {model=model,hull=hull,kind=kind,home=hull.CFrame,health=kind.Health,holder=nil}
    entries[model]=entry
    setHealth(entry,kind.Health)
    templates[model]=model:Clone()
end

local function reset()
    for player in selected do release(player) end
    -- The round moves players away before this deferred reset. Use the original authored props.
    local snapshot = {}
    for old, template in templates do table.insert(snapshot,{old,template}) end
    for _, pair in snapshot do
        local old, template = pair[1],pair[2]
        local model = template:Clone()
        local previous = entries[old]
        if previous then
            entries[old]=nil
            local hull = model:FindFirstChild("Hull") :: BasePart
            local entry: Entry = {model=model,hull=hull,kind=previous.kind,home=previous.home,health=previous.kind.Health,holder=nil}
            model.Parent=folder
            entries[model]=entry
            templates[old]=nil;templates[model]=template
            old:Destroy()
        end
    end
end

remote.OnServerEvent:Connect(function(player: Player, action: any, target: any, x: any, z: any, quarter: any)
    if action=="Cancel" then release(player);return end
    local now = os.clock()
    if now-(requests[player] or -math.huge)<Config.RequestInterval then return end
    requests[player]=now
    local char,root,head,hum = characterInfo(player)
    local state = phase()
    if action=="Attack" then
        if not Rules.canAttack(role(player),state,hum~=nil) or not char or not root or not head then return end
        if now-(attacks[player] or -math.huge)<Config.MeleeCooldown then return end
        attacks[player]=now
        local entry = if typeof(target)=="Instance" then entries[target] else nil
        if not entry or entry.health<=0 then remote:FireClient(player,"Miss");return end
        local distance = (Placement.closest(entry.hull,head.Position)-head.Position).Magnitude
        if distance>Config.MeleeRange or not lineOfSight(char,head,entry) then
            remote:FireClient(player,"Miss");return
        end
        setHealth(entry,math.max(0,entry.health-Config.MeleeDamage))
        remote:FireClient(player,"Hit",entry.health)
        return
    end
    if not Rules.canBuild(role(player),state,hum~=nil) or not char or not root or not head or not hum then
        release(player);return
    end
    if action=="Select" then
        if selected[player] then return end
        local entry = if typeof(target)=="Instance" then entries[target] else nil
        if not entry or entry.health<=0 then return end
        if entry.holder then message(player,"Outro sobrevivente está reposicionando esse objeto.");return end
        if (Placement.closest(entry.hull,root.Position)-root.Position).Magnitude>Config.PickupRange or not lineOfSight(char,head,entry) then
            message(player,"Aproxime-se do objeto com a passagem livre.");return
        end
        entry.holder=player;selected[player]=entry;expires[player]=now+Config.SelectionTimeout
        entry.model:SetAttribute("ZO_Holder",player.UserId)
        player:SetAttribute("ZO_BarricadeSelection",entry.model.Name)
        hum.WalkSpeed=Config.CarrySpeed
        remote:FireClient(player,"Selected",entry.model)
    elseif action=="Place" then
        local entry = selected[player]
        if not entry or entry.health<=0 then return end
        local ok, reason = Rules.candidate(Config.Zone,entry.kind,x,z,quarter,root.Position.X,root.Position.Y,root.Position.Z,Config.PlacementRange)
        if not ok then message(player,reason);return end
        if now>(expires[player] or 0) or (Placement.closest(entry.hull,root.Position)-root.Position).Magnitude>Config.PickupRange+2 then
            release(player,"Selecione novamente perto do objeto.");return
        end
        local cf = CFrame.new(x,Config.Zone.Floor+entry.kind.Height/2,z)*CFrame.Angles(0,quarter*math.pi/2,0)
        local clear, blocked = Placement.clear(entry.model,cf,entry.hull.Size,map)
        if not clear then message(player,blocked);return end
        if not Placement.sweep(entry.model,entry.hull,cf,quarter,map,folder) then
            message(player,"O trajeto ou a rotação atravessaria um obstáculo. Faça movimentos menores.");return
        end
        -- Prevent moving an object through a remote wall even when both ends are visible to the client.
        if not lineOfSight(char,head,entry) then message(player,"Você perdeu a linha de visão do objeto.");return end
        entry.model:PivotTo(cf)
        entry.model:SetAttribute("ZO_Quarter",quarter)
        release(player,"Barricada posicionada.")
    end
end)

local function connectPlayer(player: Player)
    player:GetPropertyChangedSignal("Team"):Connect(function() release(player) end)
    player.CharacterRemoving:Connect(function() release(player) end)
    player.CharacterAdded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid",10)
        if hum and hum:IsA("Humanoid") then hum.Died:Connect(function() release(player) end) end
    end)
end
Players.PlayerAdded:Connect(connectPlayer)
for _, player in Players:GetPlayers() do connectPlayer(player) end
Players.PlayerRemoving:Connect(function(player)
    release(player);requests[player]=nil;attacks[player]=nil
end)

RS:GetAttributeChangedSignal("ZO_RoundState"):Connect(function()
    local state = RS:GetAttribute("ZO_RoundState")
    if state~="Preparation" and state~="Active" then for player in selected do release(player) end end
    if state=="Preparation" then task.defer(reset) end
end)
task.spawn(function()
    while true do
        task.wait(.25)
        for player, entry in selected do
            local _,root,_,hum = characterInfo(player)
            if not Rules.canBuild(role(player),phase(),hum~=nil) or not root
                or os.clock()>(expires[player] or 0)
                or (Placement.closest(entry.hull,root.Position)-root.Position).Magnitude>Config.PickupRange+2 then
                release(player,"Seleção encerrada. Aproxime-se para reposicionar.")
            end
        end
    end
end)
RS:SetAttribute("ZO_BarricadesReady",true)
print("[K17 BARRICADES] Five server-authoritative props ready in warehouse stockroom")
