--!strict
-- FPS funcional provisório: mira, arma 3D local, recarga e marcador de acerto.
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local p=Players.LocalPlayer
local remote=ReplicatedStorage:WaitForChild("ZO_FireRifle")
local camera=workspace.CurrentCamera
local gui=Instance.new("ScreenGui")
gui.Name="ZO_RifleHUD"
gui.ResetOnSpawn=false
gui.Parent=p:WaitForChild("PlayerGui")
local function text(pos:UDim2,size:UDim2,fontSize:number):TextLabel
    local t=Instance.new("TextLabel")
    t.BackgroundTransparency=.35
    t.BackgroundColor3=Color3.fromRGB(11,19,24)
    t.TextColor3=Color3.fromRGB(242,233,209)
    t.Font=Enum.Font.GothamBold
    t.TextSize=fontSize
    t.Position=pos
    t.Size=size
    t.Parent=gui
    return t
end
local ammo=text(UDim2.new(1,-240,1,-90),UDim2.fromOffset(215,50),21)
local cross=text(UDim2.new(.5,-12,.5,-12),UDim2.fromOffset(24,24),25)
cross.Text="+"
cross.BackgroundTransparency=1
local vm=Instance.new("Model")
vm.Name="ZO_LocalRifle"
vm.Parent=camera
local function gunPart(name:string,size:Vector3,offset:CFrame,color:Color3):Part
    local a=Instance.new("Part")
    a.Name=name
    a.Size=size
    a.Material=Enum.Material.Metal
    a.Color=color
    a.CanCollide=false
    a.CanTouch=false
    a.CastShadow=false
    a.Anchored=true
    a.Parent=vm
    a:SetAttribute("Offset",offset)
    return a
end
gunPart("Receiver",Vector3.new(.7,.6,2.8),CFrame.new(.65,-.7,-1.8),Color3.fromRGB(50,56,58))
gunPart("Barrel",Vector3.new(.18,.18,2),CFrame.new(.65,-.55,-3.7),Color3.fromRGB(32,36,38))
gunPart("Stock",Vector3.new(.5,.45,1.2),CFrame.new(.65,-.85,-.4),Color3.fromRGB(69,72,68))
gunPart("Magazine",Vector3.new(.4,1,.45),CFrame.new(.65,-1.28,-2),Color3.fromRGB(36,41,43))
gunPart("Sight",Vector3.new(.2,.24,.3),CFrame.new(.65,-.22,-2.1),Color3.fromRGB(15,19,19))
local lastFire=0
local hitUntil=0
local function human():boolean
    return p.Team~=nil and p.Team.Name=="Humans" and ReplicatedStorage:GetAttribute("ZO_RoundState")=="Active"
end
local function update()
    ammo.Visible=human()
    cross.Visible=human()
    ammo.Text=string.format("AR-01  %d / %d",p:GetAttribute("ZO_Ammo") or 30,p:GetAttribute("ZO_Reserve") or 120)
end
p:GetAttributeChangedSignal("ZO_Ammo"):Connect(update)
p:GetAttributeChangedSignal("ZO_Reserve"):Connect(update)
p:GetPropertyChangedSignal("Team"):Connect(update)
ReplicatedStorage:GetAttributeChangedSignal("ZO_RoundState"):Connect(update)
remote.OnClientEvent:Connect(function(action:any,_damage:any)
    if action=="Hit" then hitUntil=os.clock()+.12 end
end)
UIS.InputBegan:Connect(function(input:InputObject,processed:boolean)
    if processed or not human() then return end
    if input.KeyCode==Enum.KeyCode.R then remote:FireServer("Reload") end
    if input.UserInputType==Enum.UserInputType.MouseButton1 and os.clock()-lastFire>=.11 then
        lastFire=os.clock()
        remote:FireServer("Fire",camera.CFrame.LookVector)
    end
end)
RunService.RenderStepped:Connect(function()
    camera=workspace.CurrentCamera
    if vm.Parent~=camera then vm.Parent=camera end
    local visible=human()
    p.CameraMode=if visible then Enum.CameraMode.LockFirstPerson else Enum.CameraMode.Classic
    local origin=camera.CFrame
    for _,obj in ipairs(vm:GetChildren()) do
        if obj:IsA("BasePart") then
            obj.LocalTransparencyModifier=if visible then 0 else 1
            obj.CFrame=origin*(obj:GetAttribute("Offset") :: CFrame)
        end
    end
    cross.Text=if os.clock()<hitUntil then "×" else "+"
end)
update()
print("[Zombie Outbreak] Rifle client online")
