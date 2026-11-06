--!strict
-- PC human input adapter for the MIT Source solver. Uses Humanoid's analog
-- movement input; never overwrites physical velocity, WalkSpeed or collisions.
-- Roblox retains jump/gravity/contact solving. Other devices use PlayerModule.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local Movement=require(RS:WaitForChild("K17Gameplay"):WaitForChild("SourceMovement"))
local player=Players.LocalPlayer
local bound: Humanoid?=nil
local disposed=false
local windowFocused=true
local focusLostConnection=UIS.WindowFocusReleased:Connect(function() windowFocused=false end)
local focusGainedConnection=UIS.WindowFocused:Connect(function() windowFocused=true end)
local allowed={
    [Enum.HumanoidStateType.Running]=true,[Enum.HumanoidStateType.RunningNoPhysics]=true,
    [Enum.HumanoidStateType.Landed]=true,[Enum.HumanoidStateType.Jumping]=true,
    [Enum.HumanoidStateType.Freefall]=true,
}
local function eligible(): (Humanoid?,BasePart?)
    local character=player.Character
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local phase=RS:GetAttribute("ZO_RoundState")
    local practice=phase=="Waiting" and RunService:IsStudio() and #Players:GetPlayers()==1
        and workspace:GetAttribute("ZO_BarricadePractice")==true
    local input=UIS:GetLastInputType().Name
    if disposed or not character or not character:IsDescendantOf(workspace)
        or not humanoid or humanoid.Health<=0 or not root or not root:IsA("BasePart") or root.Anchored
        or humanoid.Sit or humanoid.PlatformStand or not allowed[humanoid:GetState()]
        or not player.Team or player.Team.Name~="Humans" or not workspace.CurrentCamera
        or input=="Touch" or string.find(input,"Gamepad",1,true)~=nil
        or (phase~="Preparation" and phase~="Active" and not practice) then return nil,nil end
    return humanoid,root
end
local function release()
    if bound then
        bound:SetAttribute("ZO_SourceMovement",false)
    end
    bound=nil
end
local renderName="ZO_SourceInput"
RunService:BindToRenderStep(renderName,Enum.RenderPriority.Input.Value+2,function(dt: number)
    local humanoid,root=eligible()
    if not humanoid or not root then release();return end
    if humanoid~=bound then release();bound=humanoid end
    if not windowFocused or UIS:GetFocusedTextBox() or GuiService.MenuIsOpen then
        -- Captured input must stop active drive even when the solver observes
        -- momentum. Roblox still owns any physical falling or contact motion.
        humanoid:Move(Vector3.zero,false)
        humanoid:SetAttribute("ZO_SourceMovement",true)
        return
    end
    local function down(key: Enum.KeyCode,alias: Enum.KeyCode): number
        return if UIS:IsKeyDown(key) or UIS:IsKeyDown(alias) then 1 else 0
    end
    local x=down(Enum.KeyCode.D,Enum.KeyCode.Right)-down(Enum.KeyCode.A,Enum.KeyCode.Left)
    local z=down(Enum.KeyCode.W,Enum.KeyCode.Up)-down(Enum.KeyCode.S,Enum.KeyCode.Down)
    local look=workspace.CurrentCamera.CFrame.LookVector
    local length=math.sqrt(look.X*look.X+look.Z*look.Z)
    if length<.001 then look=root.CFrame.LookVector;length=math.sqrt(look.X*look.X+look.Z*look.Z) end
    local fx,fz=0,-1
    if length>.001 then fx=look.X/length;fz=look.Z/length end
    local wx,wz=-fz*x+fx*z,fx*x+fz*z
    local velocity=root.AssemblyLinearVelocity
    local vx,vz=Movement.step(velocity.X,velocity.Z,wx,wz,humanoid.WalkSpeed,
        humanoid.FloorMaterial~=Enum.Material.Air,dt)
    local speed=humanoid.WalkSpeed
    -- Roblox supports analog vectors below unit magnitude. This controls the
    -- requested locomotion speed without fighting its contact/jump solver.
    local drive=if speed>0 then Vector3.new(vx/speed,0,vz/speed) else Vector3.zero
    if drive.Magnitude>1 then drive=drive.Unit end
    humanoid:Move(drive,false)
    humanoid:SetAttribute("ZO_SourceMovement",true)
end)
local destroyConnection: RBXScriptConnection?
destroyConnection=script.Destroying:Connect(function()
    disposed=true;release();RunService:UnbindFromRenderStep(renderName)
    focusLostConnection:Disconnect();focusGainedConnection:Disconnect()
    if destroyConnection then destroyConnection:Disconnect() end
end)
script:SetAttribute("ZO_SourceMotorReady",true)
