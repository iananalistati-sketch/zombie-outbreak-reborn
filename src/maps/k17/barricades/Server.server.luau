--!strict
-- Sixteen server-owned assemblies; no placement preview or inventory construction.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerStorage")
local RunService=game:GetService("RunService")
local shared=RS:WaitForChild("K17Barricades")
local Config=require(shared:WaitForChild("Config"))
local Rules=require(shared:WaitForChild("Rules"))
local Physics=require(shared:WaitForChild("Physics"))
local Placement=require(shared:WaitForChild("Placement"))
local folder=workspace:WaitForChild("ZO_Barricades")
local internal=SS:WaitForChild("ZO_Gameplay")
type Entry={model: Model,hull: BasePart,kind: any,health: number,template: Model}
local entries: {[Model]: Entry}={}
local attacks: {[Player]: number}={}

local function phase(): string?
    return Rules.phase(RS:GetAttribute("ZO_RoundState"),RunService:IsStudio(),workspace:GetAttribute("ZO_BarricadePractice")==true,#Players:GetPlayers())
end
local function character(player: Player): (Model?,BasePart?,Humanoid?)
    local char=player.Character
    local head=char and char:FindFirstChild("Head")
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    if not char or not head or not head:IsA("BasePart") or not hum or hum.Health<=0 then return nil,nil,nil end
    return char,head,hum
end
local function role(player: Player): string?
    return player.Team and player.Team.Name
end
local function activate(model: Model,kind: any,template: Model): Entry
    local hull=model:FindFirstChild("Hull") :: BasePart
    model.PrimaryPart=hull;model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
    model:SetAttribute("ZO_Health",kind.Health);model:SetAttribute("ZO_MaxHealth",kind.Health)
    model:SetAttribute("ZO_Destroyed",false);model:SetAttribute("ZO_Label",kind.Label)
    hull.CustomPhysicalProperties=PhysicalProperties.new(kind.Mass/(hull.Size.X*hull.Size.Y*hull.Size.Z),Config.Physics.Friction,0,100,100)
    hull.RootPriority=127
    for _,part in model:GetDescendants() do
        if part:IsA("BasePart") and part~=hull then
            part.CanCollide=false;part.CanQuery=false;part.CanTouch=false;part.Massless=true
            local weld=Instance.new("WeldConstraint");weld.Part0=hull;weld.Part1=part;weld.Parent=hull
            part.Anchored=false
        end
    end
    hull.Anchored=false;hull:SetNetworkOwner(nil)
    local entry={model=model,hull=hull,kind=kind,health=kind.Health,template=template}
    entries[model]=entry
    return entry
end
for name,prop in Config.Props do
    local model=folder:WaitForChild(name) :: Model
    local hull=model:WaitForChild("Hull") :: BasePart
    local kind=Config.Kinds[prop.Kind]
    assert((hull.Size-Vector3.new(kind.Width,kind.Height,kind.Depth)).Magnitude<.01,"Hull/catalog mismatch: "..name)
    assert((hull.Position-Vector3.new(prop.X,prop.Y+kind.Height/2,prop.Z)).Magnitude<.01,"Home/catalog mismatch: "..name)
    model:SetAttribute("ZO_Kind",prop.Kind);model:SetAttribute("ZO_Refuge",prop.Refuge)
    activate(model,kind,model:Clone())
end
local function entryFor(part: any): Entry?
    if typeof(part)~="Instance" or not part:IsA("BasePart") or not part:IsDescendantOf(folder) then return nil end
    local model=part:FindFirstAncestorOfClass("Model")
    local entry=if model then entries[model] else nil
    return if entry and entry.health>0 then entry else nil
end
local function push(entry: Entry,direction: Vector3,force: number)
    local hull=entry.hull
    if hull.Anchored then return end
    local velocity=hull.AssemblyLinearVelocity
    local x,z=Physics.impulse(hull.AssemblyMass,velocity.X,velocity.Z,direction.X,direction.Z,force,Config.Physics.MaxSpeed)
    hull:ApplyImpulse(Vector3.new(x,0,z))
end
-- Only Combat can invoke this, after consuming ammo and tracing the first hit.
local bullet=internal:WaitForChild("PushBarricade") :: BindableFunction
bullet.OnInvoke=function(player: Player,part: BasePart,direction: Vector3): boolean
    local entry=entryFor(part)
    local _,head,hum=character(player)
    if not entry or not head or not Rules.canBuild(role(player),phase(),hum~=nil) then return false end
    if typeof(direction)~="Vector3" or not Rules.finite(direction.X) or not Rules.finite(direction.Y) or not Rules.finite(direction.Z) then return false end
    push(entry,direction,Config.Physics.BulletImpulse)
    return true
end
local damage=internal:WaitForChild("DamageBarricade") :: BindableFunction
damage.OnInvoke=function(player: Player,part: BasePart): number?
    local entry=entryFor(part)
    local char,head,hum=character(player)
    if not entry or not char or not head or not Rules.canAttack(role(player),phase(),hum~=nil) then return nil end
    local now=os.clock()
    if now-(attacks[player] or -math.huge)<Config.MeleeCooldown then return nil end
    local delta=Placement.closest(entry.hull,head.Position)-head.Position
    if delta.Magnitude>Config.MeleeRange then return nil end
    local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={char}
    local hit=if delta.Magnitude>.05 then workspace:Raycast(head.Position,delta.Unit*(delta.Magnitude+.15),params) else nil
    if delta.Magnitude>.05 and (not hit or not hit.Instance:IsDescendantOf(entry.model)) then return nil end
    attacks[player]=now
    push(entry,entry.hull.Position-head.Position,Config.Physics.MeleeImpulse)
    entry.health=math.max(0,entry.health-Config.MeleeDamage);entry.model:SetAttribute("ZO_Health",entry.health)
    if entry.health==0 then
        entry.hull.AssemblyLinearVelocity=Vector3.zero;entry.hull.AssemblyAngularVelocity=Vector3.zero;entry.hull.Anchored=true
        for _,part in entry.model:GetDescendants() do
            if part:IsA("BasePart") then part.CanCollide=false;part.CanQuery=false;part.Transparency=1 end
        end
        entry.model:SetAttribute("ZO_Destroyed",true)
    end
    return entry.health
end
local function resetEntry(entry: Entry)
    local model=entry.template:Clone();model.Parent=folder
    entries[entry.model]=nil;entry.model:Destroy()
    activate(model,entry.kind,entry.template)
end
RS:GetAttributeChangedSignal("ZO_RoundState"):Connect(function()
    if RS:GetAttribute("ZO_RoundState")=="Preparation" then
        task.defer(function()
            local snapshot={}
            for _,entry in entries do table.insert(snapshot,entry) end
            for _,entry in snapshot do resetEntry(entry) end
            table.clear(attacks)
        end)
    end
end)
Players.PlayerRemoving:Connect(function(player) attacks[player]=nil end)
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
    elapsed+=dt;if elapsed<.1 then return end;elapsed=0
    local lost={}
    for _,entry in entries do
        local hull=entry.hull
        if hull.Anchored then continue end
        local p=hull.Position
        if p.Y < -60 or math.abs(p.X)>310 or math.abs(p.Z)>310 then table.insert(lost,entry);continue end
        local velocity=hull.AssemblyLinearVelocity
        local horizontal=Vector3.new(velocity.X,0,velocity.Z)
        if horizontal.Magnitude>Config.Physics.MaxSpeed or velocity.Y>8 then
            if horizontal.Magnitude>Config.Physics.MaxSpeed then horizontal=horizontal.Unit*Config.Physics.MaxSpeed end
            hull.AssemblyLinearVelocity=horizontal+Vector3.new(0,math.min(velocity.Y,8),0)
        end
        local spin=hull.AssemblyAngularVelocity
        if spin.Magnitude>Config.Physics.MaxSpin then hull.AssemblyAngularVelocity=spin.Unit*Config.Physics.MaxSpin end
    end
    for _,entry in lost do resetEntry(entry) end
end)
RS:SetAttribute("ZO_BarricadesReady",true)
print("[K17 BARRICADES] 16 physical props across five refuges; server ownership, shot impulse and zombie melee")
