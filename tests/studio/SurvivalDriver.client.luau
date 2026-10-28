--!strict
-- Test-only client transport: requests use the production combat remotes.
local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end
local RS=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local player=Players.LocalPlayer
local channel=RS:WaitForChild("ZO_StudioSurvivalTest",40) :: RemoteEvent?
if not channel then return end
local connection: RBXScriptConnection?
connection=channel.OnClientEvent:Connect(function(serial: number,action: string,target: Vector3?)
    if action=="Stop" then
        if connection then connection:Disconnect() end
        return
    end
    local ok,problem=pcall(function()
        local character=player.Character
        local head=character and character:FindFirstChild("Head")
        assert(head and head:IsA("BasePart"),"Client character is not ready")
        if target and workspace.CurrentCamera then
            workspace.CurrentCamera.CFrame=CFrame.lookAt(head.Position,target)
        end
        -- Give the engine one frame for orientation before the production request.
        RunService.RenderStepped:Wait()
        local rifle=RS:WaitForChild("ZO_FireRifle") :: RemoteEvent
        local melee=RS:WaitForChild("ZO_Melee") :: RemoteEvent
        if action=="Fire" then
            assert(target,"Missing target")
            rifle:FireServer("Fire",(target-head.Position).Unit)
        elseif action=="Reload" then
            rifle:FireServer("Reload")
        elseif action=="Melee" then
            assert(target,"Missing target")
            melee:FireServer((target-head.Position).Unit)
        else error("Unknown validation action: "..action) end
    end)
    channel:FireServer("Ack",serial,ok,tostring(problem or ""))
end)
channel:FireServer("Ready")
