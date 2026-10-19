--!strict
-- Presentation adapter for Roblox's reusable Weapons Kit AR and animations.
-- The HandleWeld setup and named animation-track cache below are adapted from
-- Weapons Kit / Libraries / BaseWeapon, Roblox Corporation, Limited Use License.
-- Community fixes: Copyright (c) 2025 JustATortoise, MIT license.
-- Full upstream model and licenses: third_party/roblox-weapon-kit/.
-- This script never creates firing remotes, ammunition or inventory authority.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")

script:SetAttribute("ZO_EquipmentVisualsReady",false)

type Session={
    player: Player,
    character: Model?,
    humanoid: Humanoid?,
    tool: Tool?,
    tracks: {[string]: AnimationTrack},
    connections: {RBXScriptConnection},
    characterConnections: {RBXScriptConnection},
    died: RBXScriptConnection?,
    queued: boolean,
    removed: boolean,
}

local sessions: {[Player]: Session}={}
local template: Tool
local animations: Instance

local function disconnect(connections: {RBXScriptConnection})
    for _,connection in connections do connection:Disconnect() end
    table.clear(connections)
end

local function clearVisual(session: Session)
    -- Match BaseWeapon:stopAnimations: release tracks on every unequip/respawn.
    for _,track in session.tracks do
        pcall(function() track:Stop(.12);track:Destroy() end)
    end
    table.clear(session.tracks)
    local tool=session.tool
    session.tool=nil
    if tool then tool:Destroy() end
end

local function eligible(session: Session): boolean
    local player=session.player
    local humanoid=session.humanoid
    if session.removed or player.Parent~=Players or player.Character~=session.character
        or not humanoid or humanoid.Health<=0 or not session.character
        or not session.character:IsDescendantOf(workspace)
        or not player.Team or player.Team.Name~="Humans"
        or player:GetAttribute("ZO_WeaponId")~="Rifle" then return false end
    local phase=RS:GetAttribute("ZO_RoundState")
    if phase=="Preparation" or phase=="Active" then return true end
    return phase=="Waiting" and RunService:IsStudio()
        and workspace:GetAttribute("ZO_BarricadePractice")==true and #Players:GetPlayers()==1
end

local function animationTrack(session: Session,key: string): AnimationTrack?
    local cached=session.tracks[key]
    if cached then return cached end
    local humanoid=session.humanoid
    if not humanoid or humanoid.RigType~=Enum.HumanoidRigType.R15 then return nil end
    local animation=animations:FindFirstChild(key)
    if not animation or not animation:IsA("Animation") then
        warn("[K17] Borrowed Weapons Kit animation missing: "..key)
        return nil
    end
    local animator=humanoid:FindFirstChildOfClass("Animator")
    if not animator then animator=Instance.new("Animator");animator.Parent=humanoid end
    -- BaseWeapon:getAnimTrack reused with the supported Animator loading API.
    local ok,result=pcall(function() return (animator :: Animator):LoadAnimation(animation) end)
    if not ok then
        warn("[K17] Weapons Kit animation unavailable (combat continues): "..key.." / "..tostring(result))
        return nil
    end
    local track=result :: AnimationTrack
    track.Looped=key=="RifleAim"
    track.Priority=if key=="RifleReload" then Enum.AnimationPriority.Action2 else Enum.AnimationPriority.Action
    session.tracks[key]=track
    return track
end

local function buildVisual(): Tool
    local tool=template:Clone()
    tool.Name="ZO_EquippedRifle"
    tool.CanBeDropped=false
    tool.RequiresHandle=true
    tool.ManualActivationOnly=true
    tool.Enabled=false -- K-17's existing server combat remains the sole authority.
    tool:SetAttribute("ZO_EquipmentVisual",true)
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
    assert(handle and handle:IsA("BasePart"),"Weapons Kit AR lacks Handle")
    assert(model and model.PrimaryPart,"Weapons Kit AR lacks PrimaryPart")
    local attachment=model:FindFirstChild("HandleAttachment",true)
    assert(attachment and attachment:IsA("Attachment"),"Weapons Kit AR lacks HandleAttachment")

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
    return tool
end

local function refresh(session: Session)
    if session.removed then return end
    if not eligible(session) then
        clearVisual(session)
        session.player:SetAttribute("ZO_RifleVisualStatus","Idle")
        return
    end
    if not session.tool or session.tool.Parent~=session.character then
        clearVisual(session)
        local ok,result=pcall(buildVisual)
        if not ok then
            session.player:SetAttribute("ZO_RifleVisualStatus","Error")
            warn("[K17] Weapons Kit visual unavailable (combat continues): "..tostring(result))
            return
        end
        session.tool=result :: Tool
        -- A scriptless Tool inside Character uses Roblox's native RightGrip.
        -- Never call EquipTool: that would alter the independent K-17 loadout.
        session.tool.Parent=session.character
        local humanoid=session.humanoid :: Humanoid
        if humanoid.RigType==Enum.HumanoidRigType.R15 then
            local aim=animationTrack(session,"RifleAim")
            animationTrack(session,"RifleReload")
            if aim then aim:Play(.15) end
            session.player:SetAttribute("ZO_RifleVisualStatus",
                if aim and session.tracks.RifleReload then "Ready" else "AnimationUnavailable")
        else
            -- The mesh still works with native R6 grip. These animations are R15.
            session.player:SetAttribute("ZO_RifleVisualStatus","NoR15Animation")
        end
    end
    -- Reuse BaseWeapon's named reload track; the authoritative reload duration
    -- and cancel signal are the existing combat controller's replicated attrs.
    local reload=session.tracks.RifleReload
    if reload then
        if session.player:GetAttribute("ZO_Reloading")==true then
            if not reload.IsPlaying then
                local remaining=(session.player:GetAttribute("ZO_ReloadEndsAt") or 0)-workspace:GetServerTimeNow()
                local speed=if reload.Length>0 and remaining>.1 then reload.Length/remaining else 1
                reload:Play(.08,1,math.clamp(speed,.2,5))
            end
        elseif reload.IsPlaying then reload:Stop(.12) end
    end
end

local function queueRefresh(session: Session)
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
    local session: Session={player=player,character=nil,humanoid=nil,tool=nil,tracks={},
        connections={},characterConnections={},died=nil,queued=false,removed=false}
    sessions[player]=session
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
    end))
    if player.Character then characterAdded(session,player.Character) end
end

local function refreshAll()
    for _,session in sessions do queueRefresh(session) end
end

local ok,problem=xpcall(function()
    local kit=RS:WaitForChild("ZO_ReusedWeaponKit",12)
    assert(kit,"ZO_ReusedWeaponKit missing: import the reviewed Roblox Weapons Kit")
    local ar=kit:FindFirstChild("AR")
    assert(ar and ar:IsA("Tool"),"Reused Weapons Kit AR Tool missing")
    template=ar
    animations=kit:FindFirstChild("Animations") :: Instance
    assert(animations and animations:FindFirstChild("RifleAim") and animations:FindFirstChild("RifleReload"),
        "Reused Weapons Kit Animations missing")
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
    for _,player in Players:GetPlayers() do joined(player) end
    script:SetAttribute("ZO_EquipmentVisualsReady",true)
end,debug.traceback)
if not ok then warn("[K17] Equipment visuals disabled (combat continues): "..tostring(problem)) end
