--!strict
-- Presentation adapter for reviewed Roblox Weapons Kit Tools and animations.
-- The HandleWeld setup and named animation-track cache below are adapted from
-- Weapons Kit / Libraries / BaseWeapon, Roblox Corporation, Limited Use License.
-- Community fixes: Copyright (c) 2025 JustATortoise, MIT license.
-- Full upstream model and licenses: third_party/roblox-weapon-kit/.
-- This script never creates firing remotes, ammunition or inventory authority.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")

script:SetAttribute("ZO_EquipmentVisualsReady",false)

local shared=RS:WaitForChild("K17Gameplay")
local Config=require(shared:WaitForChild("Config"))
local PresentationConfig=require(shared:WaitForChild("PresentationConfig"))
local WeaponAimPose=require(shared:WaitForChild("WeaponAimPose"))

type Session={
    player: Player,
    character: Model?,
    humanoid: Humanoid?,
    tool: Tool?,
    template: Tool?,
    tracks: {[string]: AnimationTrack},
    animationSources: {[string]: Animation},
    connections: {RBXScriptConnection},
    characterConnections: {RBXScriptConnection},
    toolConnections: {RBXScriptConnection},
    died: RBXScriptConnection?,
    queued: boolean,
    removed: boolean,
}

local sessions: {[Player]: Session}={}
local assetRoot: Instance?=nil
local assetConnections: {RBXScriptConnection}={}
local missingAnimations: {[string]: boolean}={}

local function disconnect(connections: {RBXScriptConnection})
    for _,connection in connections do connection:Disconnect() end
    table.clear(connections)
end

local function clearVisual(session: Session)
    disconnect(session.toolConnections)
    -- Match BaseWeapon:stopAnimations: release tracks on every unequip/respawn.
    for _,track in session.tracks do
        pcall(function() track:Stop(.12);track:Destroy() end)
    end
    table.clear(session.tracks)
    table.clear(session.animationSources)
    local tool=session.tool
    session.tool=nil
    session.template=nil
    if tool then tool:Destroy() end
end

local function setStatus(session: Session,status: string)
    session.player:SetAttribute("ZO_WeaponVisualStatus",status)
end

local function eligible(session: Session): string?
    local player=session.player
    local humanoid=session.humanoid
    local id=player:GetAttribute("ZO_WeaponId")
    if session.removed or player.Parent~=Players or player.Character~=session.character
        or not humanoid or humanoid.Health<=0 or not session.character
        or not session.character:IsDescendantOf(workspace)
        or not player.Team or player.Team.Name~="Humans"
        or typeof(id)~="string" or not Config.Weapons[id] then return nil end
    local phase=RS:GetAttribute("ZO_RoundState")
    if phase=="Preparation" or phase=="Active" then return id end
    if phase=="Waiting" and RunService:IsStudio()
        and workspace:GetAttribute("ZO_BarricadePractice")==true and #Players:GetPlayers()==1 then return id end
    return nil
end

local function animationPrefix(tool: Tool,id: string): string
    local prefix=tool:GetAttribute("ZO_AnimationPrefix")
    if typeof(prefix)=="string" and prefix~="" then return prefix end
    return PresentationConfig.get(id).AnimationPrefix
end

local function animationTrack(session: Session,kind: string): AnimationTrack?
    local humanoid=session.humanoid
    local tool=session.tool
    if not humanoid or not tool or humanoid.RigType~=Enum.HumanoidRigType.R15 then return nil end
    local id=tool:GetAttribute("ZO_WeaponId") :: string
    local key=animationPrefix(tool,id)..kind
    local animations=assetRoot and assetRoot:FindFirstChild("Animations")
    local animation=animations and animations:FindFirstChild(key)
    local cached=session.tracks[kind]
    if cached and session.animationSources[kind]==animation then return cached end
    if cached then
        pcall(function() cached:Stop(.12);cached:Destroy() end)
        session.tracks[kind]=nil
        session.animationSources[kind]=nil
    end
    if not animation or not animation:IsA("Animation") then
        if not missingAnimations[key] then
            missingAnimations[key]=true
            warn("[K17] Borrowed Weapons Kit animation missing (combat continues): "..key)
        end
        return nil
    end
    missingAnimations[key]=nil
    local animator=humanoid:FindFirstChildOfClass("Animator")
    if not animator then animator=Instance.new("Animator");animator.Parent=humanoid end
    -- BaseWeapon:getAnimTrack reused with the supported Animator loading API.
    local ok,result=pcall(function() return (animator :: Animator):LoadAnimation(animation) end)
    if not ok then
        warn("[K17] Weapons Kit animation unavailable (combat continues): "..key.." / "..tostring(result))
        return nil
    end
    local track=result :: AnimationTrack
    -- Kit Aim is a pitch-pose bank, not a breathing/idle loop. Sampling its
    -- neutral frame prevents observers seeing an endless down/up aim sweep.
    track.Looped=false
    track.Priority=if kind=="Reload" then Enum.AnimationPriority.Action2 else Enum.AnimationPriority.Action
    if kind~="Reload" then table.insert(session.toolConnections,WeaponAimPose.bind(track)) end
    session.tracks[kind]=track
    session.animationSources[kind]=animation
    return track
end

local function mirrorReload(session: Session,tool: Tool)
    local endsAt=session.player:GetAttribute("ZO_ReloadEndsAt")
    -- Publish the deadline first: client reload audio reads it on the flag edge.
    tool:SetAttribute("ZO_ReloadEndsAt",if typeof(endsAt)=="number" then endsAt else 0)
    tool:SetAttribute("ZO_Reloading",session.player:GetAttribute("ZO_Reloading")==true)
end

local function buildVisual(template: Tool,id: string): Tool
    -- Validate the source before cloning an incomplete late import.
    local sourceHandle=template:FindFirstChild("Handle")
    local sourceModel=template:FindFirstChildOfClass("Model")
    local sourceAttachment=sourceModel and sourceModel:FindFirstChild("HandleAttachment",true)
    assert(sourceHandle and sourceHandle:IsA("BasePart"),id.." lacks Handle")
    assert(sourceModel and sourceModel.PrimaryPart,id.." lacks PrimaryPart")
    assert(sourceAttachment and sourceAttachment:IsA("Attachment"),id.." lacks HandleAttachment")
    assert(template.Archivable,id.." is not Archivable")
    local tool=template:Clone()
    local ok,problem=pcall(function()
        tool.Name="ZO_EquippedWeapon"
        tool.CanBeDropped=false
        tool.RequiresHandle=true
        tool.ManualActivationOnly=true
        tool.Enabled=false -- K-17's existing server combat remains the sole authority.
        tool:SetAttribute("ZO_EquipmentVisual",true)
        tool:SetAttribute("ZO_WeaponId",id)
        tool:SetAttribute("ZO_AnimationPrefix",animationPrefix(template,id))
        for _,descendant in tool:GetDescendants() do
            -- Defense in depth: upstream executable scripts are never activated.
            if descendant:IsA("LuaSourceContainer") then descendant:Destroy()
            elseif descendant:IsA("BasePart") then
                descendant.Anchored=false
                descendant.Massless=true
                descendant.CanCollide=false
                descendant.CanQuery=false
                descendant.CanTouch=false
            end
        end
        local handle=tool:FindFirstChild("Handle")
        local model=tool:FindFirstChildOfClass("Model")
        assert(handle and handle:IsA("BasePart"),id.." lacks Handle")
        assert(model and model.PrimaryPart,id.." lacks PrimaryPart")
        local attachment=model:FindFirstChild("HandleAttachment",true)
        assert(attachment and attachment:IsA("Attachment"),id.." lacks HandleAttachment")

        -- Reused from official BaseWeapon's server-side handle attachment setup.
        local handleOffset=model.PrimaryPart.CFrame:ToObjectSpace(attachment.WorldCFrame)
        local existing=handle:FindFirstChild("HandleWeld")
        if existing then existing:Destroy() end
        local weld=Instance.new("Weld")
        weld.Name="HandleWeld"
        weld.Part0=handle
        weld.Part1=model.PrimaryPart
        weld.C0=CFrame.new()
        weld.C1=handleOffset
        weld.Parent=handle
    end)
    if not ok then
        tool:Destroy()
        error(tostring(problem),0)
    end
    return tool
end

local queueRefresh: (Session) -> ()

local function refresh(session: Session)
    if session.removed then return end
    local id=eligible(session)
    if not id then
        clearVisual(session)
        setStatus(session,"Idle")
        return
    end
    local weapons=assetRoot and assetRoot:FindFirstChild("Weapons")
    local template=weapons and weapons:FindFirstChild(id)
    if not template or not template:IsA("Tool") then
        clearVisual(session)
        setStatus(session,"AssetMissing")
        return
    end
    if not session.tool or session.tool.Parent~=session.character or session.template~=template
        or session.tool:GetAttribute("ZO_WeaponId")~=id then
        clearVisual(session)
        local ok,result=pcall(buildVisual,template,id)
        if not ok then
            setStatus(session,"Error")
            warn("[K17] Weapons Kit visual unavailable (combat continues): "..tostring(result))
            return
        end
        session.tool=result :: Tool
        session.template=template
        mirrorReload(session,session.tool)
        -- A scriptless Tool inside Character uses Roblox's native RightGrip.
        -- Never call EquipTool: that would alter the independent K-17 loadout.
        session.tool.Parent=session.character
        table.insert(session.toolConnections,session.tool.AncestryChanged:Connect(function() queueRefresh(session) end))
    end
    local tool=session.tool :: Tool
    mirrorReload(session,tool)
    local humanoid=session.humanoid :: Humanoid
    if humanoid.RigType~=Enum.HumanoidRigType.R15 then
        -- The meshes still work with native R6 grip. Kit animations are R15.
        setStatus(session,"NoR15Animation")
        return
    end
    -- Retry missing animations after late imports; keep valid Animator tracks.
    local aim=animationTrack(session,"Aim")
    local reload=animationTrack(session,"Reload")
    if aim then WeaponAimPose.hold(aim,.15) end
    setStatus(session,if aim and reload then "Ready" else "AnimationUnavailable")
    -- Reuse BaseWeapon's named reload track; the authoritative reload duration
    -- and cancel signal are the existing combat controller's replicated attrs.
    if reload then
        if session.player:GetAttribute("ZO_Reloading")==true then
            if not reload.IsPlaying then
                local remaining=(tool:GetAttribute("ZO_ReloadEndsAt") or 0)-workspace:GetServerTimeNow()
                local speed=if reload.Length>0 and remaining>.1 then reload.Length/remaining else 1
                reload:Play(.08,1,math.clamp(speed,.2,5))
            end
        elseif reload.IsPlaying then reload:Stop(.12) end
    end
end

queueRefresh=function(session: Session)
    if session.queued or session.removed then return end
    session.queued=true
    task.defer(function()
        session.queued=false
        refresh(session)
    end)
end

local function bindHumanoid(session: Session)
    local humanoid=session.character and session.character:FindFirstChildOfClass("Humanoid")
    if humanoid==session.humanoid then return end
    if session.died then session.died:Disconnect();session.died=nil end
    clearVisual(session)
    session.humanoid=humanoid
    if humanoid then session.died=humanoid.Died:Connect(function() queueRefresh(session) end) end
end

local function characterAdded(session: Session,character: Model)
    clearVisual(session)
    disconnect(session.characterConnections)
    if session.died then session.died:Disconnect();session.died=nil end
    session.character=character
    session.humanoid=nil
    bindHumanoid(session)
    table.insert(session.characterConnections,character.AncestryChanged:Connect(function()
        queueRefresh(session)
    end))
    table.insert(session.characterConnections,character.ChildAdded:Connect(function(child)
        if child:IsA("Humanoid") then bindHumanoid(session) end
        if child:IsA("Humanoid") or child.Name=="RightHand" or child.Name=="Right Arm" then queueRefresh(session) end
    end))
    table.insert(session.characterConnections,character.ChildRemoved:Connect(function(child)
        if child==session.tool then queueRefresh(session)
        elseif child==session.humanoid then bindHumanoid(session);queueRefresh(session) end
    end))
    queueRefresh(session)
end

local function joined(player: Player)
    if sessions[player] then return end
    player:SetAttribute("ZO_RifleVisualStatus",nil)
    local session: Session={player=player,character=nil,humanoid=nil,tool=nil,template=nil,tracks={},animationSources={},
        connections={},characterConnections={},toolConnections={},died=nil,queued=false,removed=false}
    sessions[player]=session
    setStatus(session,"Idle")
    for _,attribute in {"ZO_WeaponId","ZO_Reloading","ZO_ReloadEndsAt"} do
        table.insert(session.connections,player:GetAttributeChangedSignal(attribute):Connect(function() queueRefresh(session) end))
    end
    table.insert(session.connections,player:GetPropertyChangedSignal("Team"):Connect(function() queueRefresh(session) end))
    table.insert(session.connections,player.CharacterAdded:Connect(function(character) characterAdded(session,character) end))
    table.insert(session.connections,player.CharacterRemoving:Connect(function(character)
        if session.character~=character then return end
        disconnect(session.characterConnections)
        if session.died then session.died:Disconnect();session.died=nil end
        session.character=nil;session.humanoid=nil
        clearVisual(session)
        setStatus(session,"Idle")
    end))
    if player.Character then characterAdded(session,player.Character) end
end

local function refreshAll()
    for _,session in sessions do queueRefresh(session) end
end

local function bindAssets()
    disconnect(assetConnections)
    assetRoot=RS:FindFirstChild("ZO_WeaponAssets")
    if assetRoot then
        -- A provider may publish the folder before individual reviewed Tools.
        -- Descendants also cover an Animations/Weapons folder added afterward.
        table.insert(assetConnections,assetRoot.DescendantAdded:Connect(refreshAll))
        table.insert(assetConnections,assetRoot.DescendantRemoving:Connect(refreshAll))
        table.insert(assetConnections,assetRoot.AncestryChanged:Connect(function()
            if assetRoot and assetRoot.Parent~=RS then
                disconnect(assetConnections)
                assetRoot=nil
                refreshAll()
            end
        end))
    end
    refreshAll()
end

local function removeLegacyVisuals(player: Player)
    -- One-time migration only; never remove another system's ordinary Tools.
    local containers: {Instance}={}
    if player.Character then table.insert(containers,player.Character) end
    local backpack=player:FindFirstChildOfClass("Backpack")
    if backpack then table.insert(containers,backpack) end
    for _,container in containers do
        for _,child in container:GetChildren() do
            if child:IsA("Tool") and child.Name=="ZO_EquippedRifle"
                and child:GetAttribute("ZO_EquipmentVisual")==true then child:Destroy() end
        end
    end
end

local ok,problem=xpcall(function()
    -- Register the lifecycle even if every presentation asset is absent.
    bindAssets()
    RS.ChildAdded:Connect(function(child)
        if child.Name=="ZO_WeaponAssets" then bindAssets() end
    end)
    RS.ChildRemoved:Connect(function(child)
        if child==assetRoot or child.Name=="ZO_WeaponAssets" then bindAssets() end
    end)
    Players.PlayerAdded:Connect(function(player) joined(player);refreshAll() end)
    Players.PlayerRemoving:Connect(function(player)
        local session=sessions[player]
        if session then
            session.removed=true
            disconnect(session.connections);disconnect(session.characterConnections)
            if session.died then session.died:Disconnect() end
            clearVisual(session);sessions[player]=nil
        end
        task.defer(refreshAll)
    end)
    RS:GetAttributeChangedSignal("ZO_RoundState"):Connect(refreshAll)
    workspace:GetAttributeChangedSignal("ZO_BarricadePractice"):Connect(refreshAll)
    for _,player in Players:GetPlayers() do removeLegacyVisuals(player);joined(player) end
    script:SetAttribute("ZO_EquipmentVisualsReady",true)
end,debug.traceback)
if not ok then warn("[K17] Equipment visuals disabled (combat continues): "..tostring(problem)) end
