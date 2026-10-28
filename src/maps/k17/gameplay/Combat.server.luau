--!strict
-- The server owns inventory, economy, aim validation, damage and displacement.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerStorage")
local RunService=game:GetService("RunService")
RS:SetAttribute("ZO_GameplayCombatReady",false)
local shared=RS:WaitForChild("K17Gameplay")
local Config=require(shared.Config)
local Rules=require(shared.Rules)
local LoadoutState=require(shared.LoadoutState)
local Containment=require(shared.Containment)
local function event(name: string): RemoteEvent
    local remote=Instance.new("RemoteEvent");remote.Name=name;remote.Parent=RS;return remote
end
local rifle=event("ZO_FireRifle")
local melee=event("ZO_Melee")
local effects=event("ZO_CombatFX")
local loadoutAction=event("ZO_LoadoutAction")
local internal=SS:WaitForChild("ZO_Gameplay")
local infection=internal:WaitForChild("Infect") :: BindableFunction
local barricadeDamage=internal:WaitForChild("DamageBarricade") :: BindableFunction
local barricadePush=internal:WaitForChild("PushBarricade") :: BindableFunction
local loadouts: {[Player]: any}={}
local lastRequest: {[Player]: {[string]: number}}={}
local nextMelee: {[Player]: number}={}
-- This deadline survives equip changes: switching cannot bypass either cadence.
local nextFire: {[Player]: number}={}
local rewardedSurvival: {[Player]: number}={}
local deathConnections: {[Player]: RBXScriptConnection}={}
local removingCharacters: {[Player]: Model}={}
local suppressed: {[Model]: any}={}
local rng=Random.new()

local function role(player: Player): string?
    return player.Team and player.Team.Name
end
local function character(player: Player): (Model?,BasePart?,Humanoid?)
    local char=player.Character
    local head=char and char:FindFirstChild("Head")
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    if not char or removingCharacters[player]==char or not char:IsDescendantOf(workspace)
        or not head or not head:IsA("BasePart") or not hum or hum.Health<=0 then return nil,nil,nil end
    return char,head,hum
end
local function practice(): boolean
    return RunService:IsStudio() and workspace:GetAttribute("ZO_BarricadePractice")==true
        and #Players:GetPlayers()==1 and RS:GetAttribute("ZO_RoundState")=="Waiting"
end
local function phase(): string?
    return Rules.phase(RS:GetAttribute("ZO_RoundState"),RunService:IsStudio(),workspace:GetAttribute("ZO_BarricadePractice")==true,#Players:GetPlayers())
end
local function allowed(player: Player): boolean
    local _,_,hum=character(player)
    return Rules.canFire(role(player),phase(),hum~=nil,player:GetAttribute("ZO_BarricadeSelection")~=nil)
end
local function targetRole(model: Model): string?
    local player=Players:GetPlayerFromCharacter(model)
    if player then return role(player) end
    local folder=workspace:FindFirstChild("ZO_PracticeTargets")
    if practice() and folder and model:IsDescendantOf(folder) then return model:GetAttribute("ZO_PracticeRole") end
    return nil
end
local function targetModel(part: Instance): Model?
    -- Accessories and imported rigs may contain nested Models. Resolve the
    -- actual participant/practice character instead of stopping at decoration.
    local ancestor: Instance?=part.Parent
    while ancestor and ancestor~=workspace do
        if ancestor:IsA("Model") and targetRole(ancestor)~=nil then return ancestor end
        ancestor=ancestor.Parent
    end
    return nil
end
local function sync(player: Player)
    local loadout=loadouts[player]
    if not loadout then return end
    local config,state=loadout:current()
    player:SetAttribute("ZO_WeaponId",config.Id)
    player:SetAttribute("ZO_PrimaryWeapon",loadout.primary)
    player:SetAttribute("ZO_SecondaryWeapon",loadout.secondary)
    player:SetAttribute("ZO_Credits",loadout.credits)
    player:SetAttribute("ZO_Ammo",state.ammo);player:SetAttribute("ZO_Reserve",state.reserve)
    player:SetAttribute("ZO_Reloading",state.reloadEnds>0)
    local now=os.clock();local epoch=workspace:GetServerTimeNow()
    player:SetAttribute("ZO_ReloadEndsAt",if state.reloadEnds>0 then epoch+math.max(0,state.reloadEnds-now) else 0)
    player:SetAttribute("ZO_EquipReadyAt",if loadout.equipReadyAt>now then epoch+loadout.equipReadyAt-now else 0)
end
local function award(player: Player,amount: number)
    local loadout=loadouts[player]
    if loadout and loadout:award(amount)>0 then sync(player) end
end
local function clearSuppression(model: Model?,restore: boolean)
    if not model then return end
    local entry=suppressed[model]
    if not entry then return end
    suppressed[model]=nil
    local hum=entry.hum
    -- Never overwrite a new role's speed, another effect, or a replaced Humanoid.
    if restore and model:FindFirstChildOfClass("Humanoid")==hum and hum.Health>0
        and targetRole(model)=="Zombies" and hum.WalkSpeed==entry.applied then hum.WalkSpeed=entry.base end
end
local function suppress(model: Model,hum: Humanoid,now: number)
    local entry=suppressed[model]
    if entry and entry.hum~=hum then clearSuppression(model,false);entry=nil end
    if not entry then entry={hum=hum,base=hum.WalkSpeed,untilTime=0,applied=hum.WalkSpeed};suppressed[model]=entry end
    if hum.WalkSpeed~=entry.applied then entry.base=hum.WalkSpeed end
    entry.untilTime=Containment.tagUntil(entry.untilTime,now,Config.Containment.TagSeconds)
    entry.applied=Containment.walkSpeed(entry.base,now,entry.untilTime,Config.Containment.TagWalkScale)
    hum.WalkSpeed=entry.applied
end
local function beginRound(player: Player)
    local loadout=loadouts[player]
    local id=RS:GetAttribute("ZO_RoundId")
    if loadout and role(player)=="Humans" and RS:GetAttribute("ZO_RoundState")=="Preparation"
        and typeof(id)=="number" and id>0 and loadout:beginRound(id) then
        nextFire[player]=nil;nextMelee[player]=nil;sync(player)
    end
end
local function survivorReward(player: Player)
    local loadout=loadouts[player]
    local id=RS:GetAttribute("ZO_RoundId")
    -- Round captures living human survivors before it publishes Results and
    -- changes their teams. Deferred signals must not infer eligibility later.
    if loadout and typeof(id)=="number" and id>0 and loadout.roundId==id
        and player:GetAttribute("ZO_SurvivedRound")==id
        and RS:GetAttribute("ZO_RoundState")=="Results" and RS:GetAttribute("ZO_LastWinner")=="Humans"
        and rewardedSurvival[player]~=id then
        rewardedSurvival[player]=id;award(player,Config.Economy.SurvivalReward)
    end
end
local function resetWeapons(player: Player)
    local loadout=loadouts[player]
    if not loadout then return end
    loadout:resetWeapons();nextFire[player]=nil;nextMelee[player]=nil;sync(player)
end
local function bindCharacter(player: Player,char: Model)
    if player.Character~=char or not loadouts[player] then return end
    removingCharacters[player]=nil
    if deathConnections[player] then deathConnections[player]:Disconnect();deathConnections[player]=nil end
    if role(player)=="Humans" then resetWeapons(player) end
    task.spawn(function()
        local hum=char:WaitForChild("Humanoid",10)
        if not hum or not hum:IsA("Humanoid") or player.Character~=char or removingCharacters[player]==char
            or not loadouts[player] then return end
        deathConnections[player]=hum.Died:Connect(function()
            if player.Character~=char then return end
            local loadout=loadouts[player]
            if loadout then loadout:cancelReloads();sync(player) end
            clearSuppression(char,false)
        end)
    end)
end
local function join(player: Player)
    loadouts[player]=LoadoutState.new(Config)
    sync(player)
    player.CharacterAdded:Connect(function(char: Model) bindCharacter(player,char) end)
    player.CharacterRemoving:Connect(function(char: Model)
        -- CharacterRemoving can run before Parent/Character is cleared. Deny
        -- that transition window without affecting a newer character.
        clearSuppression(char,false)
        if player.Character~=char then return end
        removingCharacters[player]=char
        if deathConnections[player] then deathConnections[player]:Disconnect();deathConnections[player]=nil end
        local loadout=loadouts[player]
        if loadout then loadout:cancelReloads();sync(player) end
    end)
    player:GetPropertyChangedSignal("Team"):Connect(function()
        local current=role(player)
        -- Results is published before survivors move into Lobby. Both hooks
        -- cover immediate/deferred signal ordering; the round guard pays once.
        survivorReward(player)
        clearSuppression(player.Character,true)
        if current=="Humans" then resetWeapons(player);beginRound(player)
        else
            local loadout=loadouts[player]
            if loadout then loadout:cancelReloads();nextMelee[player]=nil;sync(player) end
        end
    end)
    if player.Character then bindCharacter(player,player.Character) end
    beginRound(player)
end
Players.PlayerAdded:Connect(join)
for _,player in Players:GetPlayers() do join(player) end
Players.PlayerRemoving:Connect(function(player: Player)
    clearSuppression(player.Character,false)
    if deathConnections[player] then deathConnections[player]:Disconnect();deathConnections[player]=nil end
    loadouts[player]=nil;lastRequest[player]=nil;nextMelee[player]=nil;nextFire[player]=nil
    rewardedSurvival[player]=nil
    removingCharacters[player]=nil
end)
workspace:GetAttributeChangedSignal("ZO_PracticeRevision"):Connect(function()
    if practice() then
        local player=Players:GetPlayers()[1]
        if player and role(player)=="Humans" then resetWeapons(player) end
    end
end)
RS:GetAttributeChangedSignal("ZO_RoundId"):Connect(function()
    for player in loadouts do beginRound(player) end
end)
RS:GetAttributeChangedSignal("ZO_RoundState"):Connect(function()
    local state=RS:GetAttribute("ZO_RoundState")
    if state~="Active" then for model in suppressed do clearSuppression(model,true) end end
    for player,loadout in loadouts do
        if state=="Preparation" then beginRound(player)
        elseif state=="Results" then survivorReward(player) end
        if not allowed(player) then loadout:cancelReloads();sync(player) end
    end
end)
local function admit(player: Player,key: string): boolean
    if not loadouts[player] then return false end
    local now=os.clock()
    local requests=lastRequest[player]
    if not requests then requests={};lastRequest[player]=requests end
    if now-(requests[key] or -math.huge)<Config.RequestInterval then return false end
    requests[key]=now;return true
end
local messages={
    UnknownWeapon="Arma inválida.",NotOwned="Você não possui essa arma.",AlreadyEquipped="Arma já equipada.",
    InvalidTime="Ação inválida.",HumansOnly="Somente humanos usam armas.",PreparationOnly="Compre durante a preparação.",
    NotAlive="Aguarde um personagem vivo.",AlreadyOwned="Você já possui essa arma.",InsufficientCredits="Créditos insuficientes.",
    AmmoFull="Sua reserva já está completa.",InvalidWeapon="Essa arma não está disponível na loja.",
}
loadoutAction.OnServerEvent:Connect(function(player: Player,action: any,id: any)
    if action~="Buy" and action~="Ammo" and action~="Equip" then return end
    if action~="Ammo" and (typeof(id)~="string" or #id==0 or #id>32) then return end
    if action=="Ammo" and id~=nil and (typeof(id)~="string" or #id>32) then return end
    if not admit(player,"Loadout"..action) then return end
    local loadout=loadouts[player]
    if not loadout then return end
    local _,_,hum=character(player)
    local currentRole=role(player)
    local ok,reason=false,"HumansOnly"
    if action=="Equip" then
        if currentRole=="Humans" and allowed(player) then ok,reason=loadout:equip(id,os.clock())
        elseif not hum then reason="NotAlive"
        elseif currentRole=="Humans" then reason="PreparationOnly" end
    elseif action=="Buy" then
        ok,reason=loadout:buy(id,currentRole,if practice() then "Preparation" else phase(),hum~=nil,os.clock())
    else ok,reason=loadout:buyAmmo(currentRole,if practice() then "Preparation" else phase(),hum~=nil) end
    sync(player)
    local message=if not ok then messages[reason] or "Não foi possível concluir a ação."
        elseif action=="Buy" then "Arma comprada e equipada."
        elseif action=="Ammo" then "Reserva de munição abastecida." else "Arma equipada."
    loadoutAction:FireClient(player,"Result",ok,message)
end)
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
local function spreadDirection(direction: Vector3,degrees: number): Vector3
    if degrees<=0 then return direction.Unit end
    local up=if math.abs(direction.Y)>.98 then Vector3.xAxis else Vector3.yAxis
    local basis=CFrame.lookAt(Vector3.zero,direction.Unit,up)
    local radius=math.sqrt(rng:NextNumber())*math.tan(math.rad(degrees))
    local angle=rng:NextNumber()*math.pi*2
    return (direction.Unit+basis.RightVector*(math.cos(angle)*radius)+basis.UpVector*(math.sin(angle)*radius)).Unit
end
local function observers(origin: Vector3,shooter: Player): {Player}
    local result={}
    for _,observer in Players:GetPlayers() do
        local head=observer.Character and observer.Character:FindFirstChild("Head")
        if observer==shooter or (head and head:IsA("BasePart") and (head.Position-origin).Magnitude<=Config.EffectDistance) then
            table.insert(result,observer)
        end
    end
    return result
end
local function propRoot(part: Instance,folder: Instance): Instance
    local root=part
    while root.Parent and root.Parent~=folder do root=root.Parent end
    return root
end
rifle.OnServerEvent:Connect(function(player: Player,action: any,direction: any)
    if action~="Reload" and action~="Fire" then return end
    if not admit(player,action) or not allowed(player) then return end
    local loadout=loadouts[player]
    local char,head,hum=character(player)
    if not loadout or not char or not head or not hum then return end
    local config,weapon=loadout:current()
    local now=os.clock()
    if weapon:advance(now) then sync(player) end
    if now<loadout.equipReadyAt then return end
    if action=="Reload" then if weapon:reload(now) then sync(player) end;return end
    if not directionAllowed(head,direction) or now<(nextFire[player] or -math.huge) then return end
    if not weapon:fire(now) then return end
    nextFire[player]=now+config.FireInterval
    sync(player)
    local pellets=math.clamp(math.floor(config.Pellets),1,12)
    local spread=if hum.MoveDirection.Magnitude>.1 then config.MoveSpread else config.Spread
    local props=workspace:FindFirstChild("ZO_Barricades")
    local propHits: {[Instance]: any}={}
    local zombieHits: {[Model]: any}={}
    local nearby=observers(head.Position,player)
    for i=1,pellets do
        local shot=spreadDirection(direction,spread)
        local hit=trace(char,head,shot,config.Range)
        -- Limit each volley to four visual rays while still resolving every hit.
        if i<=3 or i==pellets then
            local destination=if hit then hit.Position else head.Position+shot*config.Range
            for _,observer in nearby do effects:FireClient(observer,"Shot",head.Position,destination,player.UserId,config.Id) end
        end
        if not hit then continue end
        if props and hit.Instance:IsDescendantOf(props) then
            if RS:GetAttribute("ZO_BarricadesAvailable")==true then
                local key=propRoot(hit.Instance,props)
                local entry=propHits[key]
                if not entry then entry={part=hit.Instance,direction=Vector3.zero,count=0};propHits[key]=entry end
                entry.direction+=shot;entry.count+=1
            end
            continue
        end
        local model=targetModel(hit.Instance)
        if not model or targetRole(model)~="Zombies" then continue end
        local victim=model:FindFirstChildOfClass("Humanoid")
        if not victim or victim.Health<=0 then continue end
        local hitgroup=Rules.hitgroup(hit.Instance.Name)
        local group=Config.Hitgroups[hitgroup]
        local damage=config.Damage*group.Damage
        local classScale=Config.ZombieClassKnockback
        local configured=model:GetAttribute("ZO_ClassKnockback")
        if Rules.finite(configured) then classScale=math.clamp(configured,0,3) end
        local strength=Rules.knockback(Config,damage,config.Knockback,group.Knockback,classScale,victim.FloorMaterial==Enum.Material.Air)
        local entry=zombieHits[model]
        if not entry then entry={hum=victim,damage=0,impulse=Vector3.zero,head=false};zombieHits[model]=entry end
        entry.damage+=damage;entry.impulse+=shot*strength
        entry.head=entry.head or hitgroup=="Head"
    end
    for _,entry in propHits do
        local pushed=barricadePush:Invoke(player,entry.part,entry.direction.Unit,config.PropScale*(entry.count/pellets))
        if pushed==true then rifle:FireClient(player,"PropHit",entry.count) end
    end
    for model,entry in zombieHits do
        local victim=entry.hum
        if victim.Health<=0 or targetRole(model)~="Zombies" then continue end
        local health=victim.Health
        victim:TakeDamage(entry.damage)
        rifle:FireClient(player,"Hit",entry.damage,if entry.head then "Head" else "Body")
        local root=model:FindFirstChild("HumanoidRootPart")
        if root and root:IsA("BasePart") and not root.Anchored and root.AssemblyMass>0 and root.AssemblyMass<math.huge then
            local velocity=root.AssemblyLinearVelocity
            local impulse=entry.impulse
            local strength=impulse.Magnitude
            if strength>0 and Rules.finite(velocity.X) and Rules.finite(velocity.Y) and Rules.finite(velocity.Z) then
                local unit=impulse.Unit
                local x,y,z=Containment.velocity(velocity.X,velocity.Y,velocity.Z,unit.X,unit.Y,unit.Z,strength,
                    Config.Containment.HorizontalCap,Config.Containment.UpwardCap)
                root:ApplyImpulse((Vector3.new(x,y,z)-velocity)*root.AssemblyMass)
            end
        end
        if health>0 and victim.Health<=0 then
            clearSuppression(model,false)
            if Players:GetPlayerFromCharacter(model) then award(player,Config.Economy.KillReward) end
        elseif victim.Health>0 then suppress(model,victim,now) end
    end
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
    local model=targetModel(hit.Instance)
    if model and targetRole(model)=="Humans" then
        local realVictim=Players:GetPlayerFromCharacter(model)
        local infected=infection:Invoke(player,model)
        if infected and realVictim then award(player,Config.Economy.InfectionReward) end
        melee:FireClient(player,if infected then "Infected" else "Miss")
        return
    end
    local props=workspace:FindFirstChild("ZO_Barricades")
    if props and hit.Instance:IsDescendantOf(props) and RS:GetAttribute("ZO_BarricadesAvailable")==true then
        local remaining=barricadeDamage:Invoke(player,hit.Instance)
        if typeof(remaining)=="number" then melee:FireClient(player,"Barricade",remaining);return end
    end
    melee:FireClient(player,"Miss")
end)
task.spawn(function()
    while true do
        task.wait(.05)
        local now=os.clock()
        for player,loadout in loadouts do
            local _,weapon=loadout:current()
            if weapon.reloadEnds>0 then
                if not allowed(player) then loadout:cancelReloads();sync(player)
                elseif weapon:advance(now) then sync(player) end
            end
        end
        for model,entry in suppressed do
            local victim=Players:GetPlayerFromCharacter(model)
            if not model.Parent or entry.hum.Health<=0 or targetRole(model)~="Zombies"
                or (victim and victim.Character~=model) then clearSuppression(model,false)
            elseif now>=entry.untilTime then clearSuppression(model,true) end
        end
    end
end)
RS:SetAttribute("ZO_GameplayCombatReady",true)
print("[K17 GAMEPLAY] Server arsenal, economy, containment, reload and shared zombie melee ready")
