--!strict
-- Controls and crouch-camera interpolation adapted from voximity/extract,
-- Client/Character.lua (45afa80c93eeb8f4b21a84bab8a4b14a30ff33cc).
-- Copyright (c) 2019 voximity, MIT. See third_party/extract-movement/.
-- Integration: server-approved stance, late characters/remotes and owned offsets.
-- This client never writes WalkSpeed, joints, collision, Camera.CFrame or FOV.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local CAS=game:GetService("ContextActionService")
local GuiService=game:GetService("GuiService")
local player=Players.LocalPlayer
local Config=require(RS:WaitForChild("K17Gameplay"):WaitForChild("MovementConfig"))
local connections: {RBXScriptConnection}={}
local characterConnections: {RBXScriptConnection}={}
local humanoidConnections: {RBXScriptConnection}={}
local character: Model?=nil
local humanoid: Humanoid?=nil
local remote: RemoteEvent?=nil
local lastSent: string?=nil
local lastSentAt=-math.huge
local sendQueued=false
local disposed=false
local removing=false
local walkHeld,walkToggle=false,false
local crouchHeld,crouchToggle=false,false
local baseline: Vector3?=nil
local lastOffset: Vector3?=nil
local cameraReleased=false
local cameraDrop=0
local cameraForward=0

local function disconnect(items: {RBXScriptConnection})
    for _,connection in items do connection:Disconnect() end
    table.clear(items)
end
local function connect(signal: RBXScriptSignal,fn: any)
    table.insert(connections,signal:Connect(fn))
end
local function menuOpen(): boolean
    return player:GetAttribute("ZO_ShopOpen")==true or player:GetAttribute("ZO_TacticalMapOpen")==true
        or GuiService.MenuIsOpen==true or UIS:GetFocusedTextBox()~=nil
end
local function living(): boolean
    return not removing and character~=nil and player.Character==character
        and character:IsDescendantOf(workspace) and humanoid~=nil and humanoid.Health>0
end
local function canInput(): boolean
    if disposed or not living() or menuOpen() then return false end
    local team=player.Team
    if not team or (team.Name~="Humans" and team.Name~="Zombies" and team.Name~="Lobby") then return false end
    local phase=RS:GetAttribute("ZO_RoundState")
    return phase=="Waiting" or phase=="Intermission" or phase=="Preparation" or phase=="Active"
end
local function desiredMode(): string
    if not canInput() then return "Run" end
    -- Same stance precedence as extract; Shift is tactical walking in K-17.
    if crouchHeld or crouchToggle then return "Crouch" end
    if walkHeld or walkToggle then return "Walk" end
    return "Run"
end
local sendIntent: ()->()
sendIntent=function()
    if disposed or not remote or remote.Parent~=RS then return end
    local mode=desiredMode()
    if lastSent==mode then return end
    local remaining=Config.RequestInterval+.01-(os.clock()-lastSentAt)
    if remaining>.0001 then
        if not sendQueued then
            sendQueued=true
            task.delay(remaining,function()
                sendQueued=false
                sendIntent() -- Send the latest intent, including quick release.
            end)
        end
        return
    end
    lastSent=mode
    lastSentAt=os.clock()
    remote:FireServer(mode)
end
local function buttons()
    for _,name in {"ZO_Walk","ZO_Crouch"} do
        local button=CAS:GetButton(name)
        if button then button.Visible=UIS.TouchEnabled and canInput() end
    end
end
local function resetInput()
    walkHeld=false;walkToggle=false;crouchHeld=false;crouchToggle=false
    sendIntent();buttons()
end
local function restoreCamera()
    if humanoid and baseline and lastOffset and humanoid.CameraOffset==lastOffset then
        humanoid.CameraOffset=baseline
    end
    baseline=nil;lastOffset=nil;cameraDrop=0;cameraForward=0;cameraReleased=false
end
local refreshHumanoid: ()->()
local function bindHumanoid(nextHumanoid: Humanoid?)
    if nextHumanoid==humanoid then return end
    restoreCamera();disconnect(humanoidConnections)
    humanoid=nextHumanoid
    lastSent=nil
    if humanoid then
        local boundHumanoid=humanoid
        baseline=humanoid.CameraOffset
        table.insert(humanoidConnections,humanoid.Died:Connect(function()
            if humanoid~=boundHumanoid then return end
            resetInput();restoreCamera()
        end))
        for _,name in {"ZO_Crouching","ZO_CrouchDrop","ZO_StandBlocked","ZO_MovementMode"} do
            table.insert(humanoidConnections,humanoid:GetAttributeChangedSignal(name):Connect(buttons))
        end
    end
    resetInput()
end
refreshHumanoid=function()
    local nextHumanoid=if character and not removing and character:IsDescendantOf(workspace)
        then character:FindFirstChildOfClass("Humanoid") else nil
    bindHumanoid(nextHumanoid)
end
local function bindCharacter(nextCharacter: Model)
    if disposed or player.Character~=nextCharacter then return end
    resetInput();bindHumanoid(nil);disconnect(characterConnections)
    character=nextCharacter;removing=false;lastSent=nil
    table.insert(characterConnections,nextCharacter.ChildAdded:Connect(function(item)
        if character~=nextCharacter then return end
        if item:IsA("Humanoid") then refreshHumanoid() end
    end))
    table.insert(characterConnections,nextCharacter.ChildRemoved:Connect(function(item)
        if character~=nextCharacter then return end
        if item==humanoid then refreshHumanoid() end
    end))
    table.insert(characterConnections,nextCharacter.AncestryChanged:Connect(function()
        if character~=nextCharacter then return end
        if not nextCharacter:IsDescendantOf(workspace) then resetInput() end
        refreshHumanoid()
    end))
    refreshHumanoid();sendIntent();buttons()
end
local function bindRemote()
    local found=RS:FindFirstChild("ZO_MoveIntent")
    local nextRemote=if found and found:IsA("RemoteEvent") then found else nil
    if nextRemote~=remote then remote=nextRemote;lastSent=nil;lastSentAt=-math.huge end
    sendIntent()
end
local function walkAction(_: string,state: Enum.UserInputState,input: InputObject): Enum.ContextActionResult
    if not canInput() then resetInput();return Enum.ContextActionResult.Pass end
    local toggle=input.UserInputType==Enum.UserInputType.Touch or input.KeyCode==Enum.KeyCode.ButtonL3
    if state==Enum.UserInputState.Cancel then walkHeld=false;walkToggle=false
    elseif toggle then
        if state==Enum.UserInputState.Begin then walkToggle=not walkToggle end
    elseif state==Enum.UserInputState.Begin then walkHeld=true
    elseif state==Enum.UserInputState.End then walkHeld=false end
    sendIntent()
    return Enum.ContextActionResult.Sink
end
local function crouchAction(_: string,state: Enum.UserInputState,input: InputObject): Enum.ContextActionResult
    if not canInput() then resetInput();return Enum.ContextActionResult.Pass end
    local toggle=input.UserInputType==Enum.UserInputType.Touch or input.KeyCode==Enum.KeyCode.C
        or input.KeyCode==Enum.KeyCode.ButtonB
    if state==Enum.UserInputState.Cancel then crouchHeld=false;crouchToggle=false
    elseif toggle then
        if state==Enum.UserInputState.Begin then crouchToggle=not crouchToggle end
    elseif state==Enum.UserInputState.Begin then crouchHeld=true
    elseif state==Enum.UserInputState.End then crouchHeld=false end
    sendIntent()
    return Enum.ContextActionResult.Sink
end
CAS:BindActionAtPriority("ZO_Walk",walkAction,true,1800,Enum.KeyCode.LeftShift,Enum.KeyCode.RightShift,Enum.KeyCode.ButtonL3)
CAS:BindActionAtPriority("ZO_Crouch",crouchAction,true,1800,Enum.KeyCode.LeftControl,Enum.KeyCode.RightControl,Enum.KeyCode.C,Enum.KeyCode.ButtonB)
CAS:SetTitle("ZO_Walk","Andar");CAS:SetPosition("ZO_Walk",UDim2.new(0,24,1,-260))
CAS:SetTitle("ZO_Crouch","Agachar");CAS:SetPosition("ZO_Crouch",UDim2.new(0,112,1,-260))
for _,name in {"ZO_Walk","ZO_Crouch"} do
    local button=CAS:GetButton(name)
    if button then button.Size=UDim2.fromOffset(76,54) end
end
connect(UIS.WindowFocusReleased,resetInput)
connect(UIS.TextBoxFocused,resetInput)
connect(UIS.TextBoxFocusReleased,function() buttons() end)
connect(GuiService.MenuOpened,resetInput)
connect(GuiService.MenuClosed,buttons)
connect(UIS.JumpRequest,function()
    -- The server may retain crouch if there is not enough room to stand.
    crouchHeld=false;crouchToggle=false;sendIntent()
end)
connect(player.CharacterAdded,bindCharacter)
connect(player.CharacterRemoving,function(oldCharacter)
    if oldCharacter~=character then return end
    removing=true;resetInput();bindHumanoid(nil);disconnect(characterConnections);character=nil
end)
connect(player:GetPropertyChangedSignal("Team"),resetInput)
for _,name in {"ZO_ShopOpen","ZO_TacticalMapOpen"} do
    connect(player:GetAttributeChangedSignal(name),function()
        if menuOpen() then resetInput() else buttons() end
    end)
end
connect(RS:GetAttributeChangedSignal("ZO_RoundState"),function()
    if not canInput() then resetInput() else sendIntent();buttons() end
end)
connect(RS.ChildAdded,function(item) if item.Name=="ZO_MoveIntent" then bindRemote() end end)
connect(RS.ChildRemoved,function(item) if item==remote then bindRemote() end end)
bindRemote()
if player.Character then bindCharacter(player.Character) end

local renderName="ZO_MovementCamera"
RunService:UnbindFromRenderStep(renderName)
RunService:BindToRenderStep(renderName,Enum.RenderPriority.Camera.Value-2,function(dt: number)
    if disposed then return end
    if not living() or not humanoid then return end
    if not baseline then baseline=humanoid.CameraOffset end
    if humanoid.CameraOffset~=(lastOffset or baseline) then
        -- Another camera system now owns the property. Yield until respawn;
        -- subtracting our old offset from its new frame would introduce drift.
        lastOffset=nil;cameraReleased=true
    end
    if cameraReleased then return end
    local target=0
    local targetForward=0
    if humanoid:GetAttribute("ZO_Crouching")==true then
        local drop=humanoid:GetAttribute("ZO_CrouchDrop")
        target=if typeof(drop)=="number" and drop==drop then math.clamp(drop,0,4) else Config.CrouchDrop
        -- Match the server Root Motor's local forward shift at this rig's scale.
        targetForward=Config.CrouchForward*math.clamp(target/Config.CrouchDrop,.6,1.5)
    end
    local alpha=1-math.exp(-math.clamp(dt,0,.25)*Config.CameraResponse)
    cameraDrop+=(target-cameraDrop)*alpha
    cameraForward+=(targetForward-cameraForward)*alpha
    if math.abs(cameraDrop-target)<.0001 then cameraDrop=target end
    if math.abs(cameraForward-targetForward)<.0001 then cameraForward=targetForward end
    humanoid.CameraOffset=(baseline :: Vector3)+Vector3.new(0,-cameraDrop,cameraForward)
    -- Engine Vector3 properties round values. Track the actual stored value.
    lastOffset=humanoid.CameraOffset
end)
connect(script.Destroying,function()
    if disposed then return end
    resetInput()
    -- A queued LocalScript timer may be cancelled when its script is destroyed.
    -- The server coalesces intent, so deliver the final release before cleanup.
    if remote and remote.Parent==RS and lastSent~="Run" then remote:FireServer("Run") end
    disposed=true
    restoreCamera()
    RunService:UnbindFromRenderStep(renderName)
    CAS:UnbindAction("ZO_Walk");CAS:UnbindAction("ZO_Crouch")
    disconnect(connections);disconnect(characterConnections);disconnect(humanoidConnections)
end)
