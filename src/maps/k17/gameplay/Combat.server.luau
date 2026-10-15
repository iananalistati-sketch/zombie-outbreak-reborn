--!strict
-- All damage, rate limits, ammo, reload completion and hit detection are server-owned.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerStorage")
local RunService=game:GetService("RunService")
local shared=RS:WaitForChild("K17Gameplay")
local Config=require(shared.Config)
local Rules=require(shared.Rules)
local WeaponState=require(shared.WeaponState)
local function event(name: string): RemoteEvent
    local remote=Instance.new("RemoteEvent");remote.Name=name;remote.Parent=RS;return remote
end
local rifle=event("ZO_FireRifle")
local melee=event("ZO_Melee")
local effects=event("ZO_CombatFX")
local internal=SS:WaitForChild("ZO_Gameplay")
local infection=internal:WaitForChild("Infect") :: BindableFunction
local barricadeDamage=internal:WaitForChild("DamageBarricade") :: BindableFunction
local barricadePush=internal:WaitForChild("PushBarricade") :: BindableFunction
local weapons: {[Player]: any}={}
local lastRequest: {[Player]: {[string]: number}}={}
local nextMelee: {[Player]: number}={}
local function role(player: Player): string?
    return player.Team and player.Team.Name
end
local function character(player: Player): (Model?,BasePart?,Humanoid?)
    local char=player.Character
    local head=char and char:FindFirstChild("Head")
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    if not char or not head or not head:IsA("BasePart") or not hum or hum.Health<=0 then return nil,nil,nil end
    return char,head,hum
end
local function phase(): string?
    return Rules.phase(RS:GetAttribute("ZO_RoundState"),RunService:IsStudio(),workspace:GetAttribute("ZO_BarricadePractice")==true,#Players:GetPlayers())
end
local function allowed(player: Player): boolean
    local _,_,hum=character(player)
    return Rules.canFire(role(player),phase(),hum~=nil,player:GetAttribute("ZO_BarricadeSelection")~=nil)
end
local function sync(player: Player)
    local weapon=weapons[player]
    if not weapon then return end
    player:SetAttribute("ZO_Ammo",weapon.ammo);player:SetAttribute("ZO_Reserve",weapon.reserve)
    player:SetAttribute("ZO_Reloading",weapon.reloadEnds>0)
    player:SetAttribute("ZO_ReloadEndsAt",if weapon.reloadEnds>0 then workspace:GetServerTimeNow()+math.max(0,weapon.reloadEnds-os.clock()) else 0)
end
local function reset(player: Player)
    weapons[player]=WeaponState.new(Config.Rifle);nextMelee[player]=nil;sync(player)
end
local function join(player: Player)
    reset(player)
    player.CharacterAdded:Connect(function() reset(player) end)
    player:GetPropertyChangedSignal("Team"):Connect(function()
        if role(player)=="Humans" then reset(player)
        elseif weapons[player] then weapons[player]:cancelReload();nextMelee[player]=nil;sync(player) end
    end)
end
Players.PlayerAdded:Connect(join)
for _,player in Players:GetPlayers() do join(player) end
Players.PlayerRemoving:Connect(function(player) weapons[player]=nil;lastRequest[player]=nil;nextMelee[player]=nil end)
workspace:GetAttributeChangedSignal("ZO_PracticeRevision"):Connect(function()
    if RunService:IsStudio() and #Players:GetPlayers()==1 and phase()=="Active" and RS:GetAttribute("ZO_RoundState")=="Waiting" then
        reset(Players:GetPlayers()[1])
    end
end)
RS:GetAttributeChangedSignal("ZO_RoundState"):Connect(function()
    local state=RS:GetAttribute("ZO_RoundState")
    for player,weapon in weapons do
        if state=="Preparation" and role(player)=="Humans" then reset(player)
        elseif not allowed(player) and weapon:cancelReload() then sync(player) end
    end
end)
local function admit(player: Player,key: string): boolean
    local now=os.clock()
    local requests=lastRequest[player]
    if not requests then requests={};lastRequest[player]=requests end
    if now-(requests[key] or -math.huge)<Config.RequestInterval then return false end
    requests[key]=now;return true
end
local function directionAllowed(head: BasePart,direction: any): boolean
    if typeof(direction)~="Vector3" or not Rules.direction(direction.X,direction.Y,direction.Z) then return false end
    local forward=head.CFrame.LookVector
    return Rules.facing(direction.X,direction.Z,forward.X,forward.Z)
end
local function trace(char: Model,head: BasePart,direction: Vector3,distance: number): RaycastResult?
    local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances={char}
    return workspace:Raycast(head.Position,direction.Unit*distance,params)
end
local function targetRole(model: Model): string?
    local player=Players:GetPlayerFromCharacter(model)
    if player then return role(player) end
    local practice=workspace:FindFirstChild("ZO_PracticeTargets")
    if RunService:IsStudio() and #Players:GetPlayers()==1 and workspace:GetAttribute("ZO_BarricadePractice")==true
        and practice and model:IsDescendantOf(practice) then return model:GetAttribute("ZO_PracticeRole") end
    return nil
end
local function nearbyEffect(origin: Vector3,position: Vector3,shooter: Player)
    for _,observer in Players:GetPlayers() do
        local head=observer.Character and observer.Character:FindFirstChild("Head")
        if observer==shooter or (head and head:IsA("BasePart") and (head.Position-origin).Magnitude<=Config.EffectDistance) then
            effects:FireClient(observer,"Shot",origin,position,shooter.UserId)
        end
    end
end
rifle.OnServerEvent:Connect(function(player: Player,action: any,direction: any)
    if action~="Reload" and action~="Fire" then return end
    if not admit(player,action) or not allowed(player) then return end
    local weapon=weapons[player]
    local char,head=character(player)
    if not weapon or not char or not head then return end
    local now=os.clock()
    if weapon:advance(now) then sync(player) end
    if action=="Reload" then if weapon:reload(now) then sync(player) end;return end
    if action~="Fire" or not directionAllowed(head,direction) then return end
    local accepted=weapon:fire(now)
    if not accepted then return end
    sync(player)
    local hit=trace(char,head,direction,Config.Rifle.Range)
    nearbyEffect(head.Position,if hit then hit.Position else head.Position+direction.Unit*Config.Rifle.Range,player)
    if not hit then return end
    local props=workspace:FindFirstChild("ZO_Barricades")
    if props and hit.Instance:IsDescendantOf(props) and RS:GetAttribute("ZO_BarricadesReady")==true then
        barricadePush:Invoke(player,hit.Instance,direction)
        return
    end
    local model=hit.Instance:FindFirstAncestorOfClass("Model")
    if not model or targetRole(model)~="Zombies" then return end
    local hum=model:FindFirstChildOfClass("Humanoid")
    local root=model:FindFirstChild("HumanoidRootPart")
    if not hum or hum.Health<=0 then return end
    local group=Config.Hitgroups[Rules.hitgroup(hit.Instance.Name)]
    local damage=Config.Rifle.Damage*group.Damage
    local classScale=Config.ZombieClassKnockback
    local configured=model:GetAttribute("ZO_ClassKnockback")
    if Rules.finite(configured) then classScale=math.clamp(configured,0,3) end
    local strength=Rules.knockback(Config,damage,Config.Rifle.Knockback,group.Knockback,classScale,hum.FloorMaterial==Enum.Material.Air)
    hum:TakeDamage(damage)
    if root and root:IsA("BasePart") and not root.Anchored and root.AssemblyMass<math.huge then
        root:ApplyImpulse(direction.Unit*root.AssemblyMass*strength)
    end
    rifle:FireClient(player,"Hit",damage)
end)
melee.OnServerEvent:Connect(function(player: Player,direction: any)
    if not admit(player,"Melee") then return end
    local char,head,hum=character(player)
    if not Rules.canMelee(role(player),phase(),hum~=nil) or not char or not head or not directionAllowed(head,direction) then return end
    local now=os.clock()
    if now<(nextMelee[player] or -math.huge) then return end
    nextMelee[player]=now+Config.Melee.Cooldown
    local hit=trace(char,head,direction,Config.Melee.Range)
    if not hit then melee:FireClient(player,"Miss");return end
    local model=hit.Instance:FindFirstAncestorOfClass("Model")
    if model and targetRole(model)=="Humans" then
        local infected=infection:Invoke(player,model)
        melee:FireClient(player,if infected then "Infected" else "Miss")
        return
    end
    local props=workspace:FindFirstChild("ZO_Barricades")
    if props and hit.Instance:IsDescendantOf(props) and RS:GetAttribute("ZO_BarricadesReady")==true then
        local remaining=barricadeDamage:Invoke(player,hit.Instance)
        if typeof(remaining)=="number" then melee:FireClient(player,"Barricade",remaining);return end
    end
    melee:FireClient(player,"Miss")
end)
task.spawn(function()
    while true do
        task.wait(.05)
        for player,weapon in weapons do
            if weapon.reloadEnds>0 then
                if not allowed(player) then weapon:cancelReload();sync(player)
                elseif weapon:advance(os.clock()) then sync(player) end
            end
        end
    end
end)
RS:SetAttribute("ZO_GameplayCombatReady",true)
print("[K17 GAMEPLAY] Server rifle, timed reload and shared zombie melee ready")
