--!strict
-- Server accepts stance names only. Shared MovementState composes role speed,
-- stance and hit containment; this controller never writes WalkSpeed directly.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local shared=RS:WaitForChild("K17Gameplay")
local Config=require(shared:WaitForChild("MovementConfig"))
local State=require(shared:WaitForChild("MovementState"))
local Pose=require(shared:WaitForChild("MovementPose"))
local remote=Instance.new("RemoteEvent")
remote.Name="ZO_MoveIntent"
remote.Parent=RS
local sessions: {[Player]: any}={}
local connections: {RBXScriptConnection}={}
local allowedPhases={Waiting=true,Intermission=true,Preparation=true,Active=true}
local allowedRoles={Lobby=true,Humans=true,Zombies=true}
local modes={Run=1,Walk=Config.WalkScale,Crouch=Config.CrouchScale,Sprint=Config.SprintScale}

local function disconnect(list)
    for _,connection in list do connection:Disconnect() end
    table.clear(list)
end
local function eligible(session): boolean
    local player=session.player
    local character=session.character
    local humanoid=session.humanoid
    return player.Parent==Players and player.Character==character and character~=nil
        and character:IsDescendantOf(workspace) and humanoid~=nil and humanoid.Health>0
        and player.Team~=nil and allowedRoles[player.Team.Name]==true
        and allowedPhases[RS:GetAttribute("ZO_RoundState")]==true
end
local function clearCharacter(session)
    disconnect(session.characterConnections)
    if session.humanoid then
        State.setMode(session.humanoid,"Run",1,os.clock())
        session.humanoid:SetAttribute("ZO_Crouching",false)
        session.humanoid:SetAttribute("ZO_StandBlocked",false)
        session.humanoid:SetAttribute("ZO_CrouchDrop",0)
    end
    if session.pose then session.pose:destroy() end
    session.character=nil;session.humanoid=nil;session.pose=nil
    session.desired="Run";session.mode="Run";session.alpha=0
end
local function refreshCharacter(session)
    local character=session.character
    if not character or session.player.Character~=character then return end
    local humanoid=character:FindFirstChildOfClass("Humanoid")
    if humanoid~=session.humanoid then
        if session.pose then session.pose:destroy();session.pose=nil end
        session.humanoid=humanoid;session.desired="Run";session.mode="Run";session.alpha=0
    end
    if humanoid and not session.pose then
        session.pose=Pose.new(character,Config)
        humanoid:SetAttribute("ZO_CrouchDrop",if session.pose then session.pose.drop else 0)
        humanoid:SetAttribute("ZO_Crouching",false)
        humanoid:SetAttribute("ZO_StandBlocked",false)
    end
end
local function bindCharacter(session,character: Model)
    clearCharacter(session)
    session.character=character
    refreshCharacter(session)
    table.insert(session.characterConnections,character.DescendantAdded:Connect(function(item)
        if item:IsA("Humanoid") or item:IsA("Motor6D") or item:IsA("BasePart") then refreshCharacter(session) end
    end))
    table.insert(session.characterConnections,character.AncestryChanged:Connect(function()
        if not character:IsDescendantOf(workspace) then session.desired="Run" end
    end))
end
local function joined(player: Player)
    if sessions[player] then return end
    local session={player=player,character=nil,humanoid=nil,pose=nil,desired="Run",mode="Run",alpha=0,
        connections={},characterConnections={}}
    sessions[player]=session
    table.insert(session.connections,player.CharacterAdded:Connect(function(character) bindCharacter(session,character) end))
    table.insert(session.connections,player.CharacterRemoving:Connect(function(character)
        if session.character==character then clearCharacter(session) end
    end))
    table.insert(session.connections,player:GetPropertyChangedSignal("Team"):Connect(function() session.desired="Run" end))
    if player.Character then bindCharacter(session,player.Character) end
end
table.insert(connections,remote.OnServerEvent:Connect(function(player: Player,mode: any)
    local session=sessions[player]
    if not session or type(mode)~="string" or not modes[mode] or not eligible(session) then return end
    if mode=="Crouch" and not session.pose then return end
    -- Coalesce the latest valid intent. Dropping a quick key release could
    -- otherwise strand the player crouched; physics work remains fixed-rate.
    session.desired=mode
end))
table.insert(connections,Players.PlayerAdded:Connect(joined))
table.insert(connections,Players.PlayerRemoving:Connect(function(player: Player)
    local session=sessions[player]
    if session then clearCharacter(session);disconnect(session.connections);sessions[player]=nil end
end))
table.insert(connections,RS:GetAttributeChangedSignal("ZO_RoundState"):Connect(function()
    if not allowedPhases[RS:GetAttribute("ZO_RoundState")] then
        for _,session in sessions do session.desired="Run" end
    end
end))
for _,player in Players:GetPlayers() do joined(player) end
local elapsed=0
table.insert(connections,RunService.Heartbeat:Connect(function(dt: number)
    elapsed+=dt
    if elapsed<math.max(Config.UpdateInterval,Config.RequestInterval) then return end
    local step=elapsed;elapsed=0
    local now=os.clock()
    for _,session in sessions do
        local humanoid=session.humanoid
        if not humanoid or humanoid.Health<=0 or not session.character
            or not session.character:IsDescendantOf(workspace) then continue end
        local desired=if eligible(session) then session.desired else "Run"
        local pose=session.pose
        local blocked=false
        if desired=="Crouch" and not pose then desired="Run" end
        if desired~="Crouch" and pose and (session.mode=="Crouch" or session.alpha>.001) then
            blocked=not pose:canStand(workspace)
            if blocked then desired="Crouch" end
        end
        -- Only a stance change or a Round role reset is an intent update.
        -- Reapplying setMode every heartbeat would steal external effect ownership.
        if session.mode~=desired or humanoid:GetAttribute("ZO_MovementMode")~=desired then
            State.setMode(humanoid,desired,modes[desired],now)
            session.mode=desired
        end
        State.step(humanoid,now)
        humanoid:SetAttribute("ZO_Crouching",desired=="Crouch")
        humanoid:SetAttribute("ZO_StandBlocked",blocked)
        local target=if desired=="Crouch" then 1 else 0
        session.alpha+=(target-session.alpha)*(1-math.exp(-Config.PoseResponse*step))
        if math.abs(session.alpha-target)<.001 then session.alpha=target end
        if pose then pose:update(session.alpha) end
    end
end))
table.insert(connections,script.Destroying:Connect(function()
    disconnect(connections)
    for _,session in sessions do clearCharacter(session);disconnect(session.connections) end
    table.clear(sessions)
    remote:Destroy()
end))
script:SetAttribute("ZO_MovementReady",true)
