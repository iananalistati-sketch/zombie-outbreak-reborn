--!strict
-- One local spotlight. No remotes, inventory authority or character physics.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local CAS=game:GetService("ContextActionService")
local UIS=game:GetService("UserInputService")
local Gui=game:GetService("GuiService")
local player=Players.LocalPlayer
local requested=true
local disposed=false
local mount: Part?=nil
local light: SpotLight?=nil
local action="ZO_Flashlight"
local render="ZO_FlashlightCamera"
local function menu()
    return Gui.MenuIsOpen or player:GetAttribute("ZO_ShopOpen")==true
        or player:GetAttribute("ZO_TacticalMapOpen")==true or player:GetAttribute("ZO_ScoreboardOpen")==true
end
local function playable()
    local char=player.Character;local hum=char and char:FindFirstChildOfClass("Humanoid")
    local phase=RS:GetAttribute("ZO_RoundState")
    return hum~=nil and hum.Health>0 and player.Team~=nil and player.Team.Name~="Lobby"
        and (phase=="Training" or phase=="Preparation" or phase=="Active")
        and player:GetAttribute("ZO_Spectating")~=true and player:GetAttribute("ZO_SpawnPending")~=true
end
CAS:BindActionAtPriority(action,function(_,state)
    if UIS:GetFocusedTextBox() or menu() or not playable() then return Enum.ContextActionResult.Pass end
    if state==Enum.UserInputState.Begin then requested=not requested end
    return Enum.ContextActionResult.Sink
end,true,1900,Enum.KeyCode.F,Enum.KeyCode.DPadRight)
CAS:SetTitle(action,"Lanterna");CAS:SetPosition(action,UDim2.new(1,-150,1,-255))
Run:UnbindFromRenderStep(render)
Run:BindToRenderStep(render,Enum.RenderPriority.Camera.Value+2,function()
    if disposed then return end
    local camera=workspace.CurrentCamera
    local usable=playable() and not menu()
    local enabled=camera~=nil and usable and requested
    if enabled and (not mount or not mount.Parent) then
        if mount then mount:Destroy() end
        local stale=camera:FindFirstChild("ZO_FlashlightMount");if stale then stale:Destroy() end
        local part=Instance.new("Part");part.Name="ZO_FlashlightMount";part.Size=Vector3.new(.05,.05,.05)
        part.Anchored=true;part.Transparency=1;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false;part.CastShadow=false
        part.Parent=camera;mount=part
        local beam=Instance.new("SpotLight");beam.Name="Beam";beam.Face=Enum.NormalId.Front
        beam.Angle=64;beam.Range=48;beam.Brightness=2.4;beam.Color=Color3.fromRGB(242,237,216)
        beam.Shadows=true;beam.Parent=part;light=beam
    end
    if mount and mount.Parent and camera then mount.Parent=camera;mount.CFrame=camera.CFrame*CFrame.new(.2,-.15,-.55) end
    if light and light.Parent then light.Enabled=enabled end
    player:SetAttribute("ZO_FlashlightOn",enabled)
    local button=CAS:GetButton(action);if button then button.Visible=usable end
end)
script.Destroying:Connect(function()
    disposed=true;Run:UnbindFromRenderStep(render);CAS:UnbindAction(action)
    if mount then mount:Destroy();mount=nil;light=nil end
    player:SetAttribute("ZO_FlashlightOn",false)
end)
