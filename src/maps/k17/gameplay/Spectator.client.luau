--!nonstrict
-- Camera only; never moves characters or requests a role/respawn from server.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local CAS=game:GetService("ContextActionService")
local UIS=game:GetService("UserInputService")
local State=require(RS:WaitForChild("K17Gameplay"):WaitForChild("SpectatorState"))
local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
local old=playerGui:FindFirstChild("ZO_SpectatorHUD");if old then old:Destroy() end
local gui=Instance.new("ScreenGui");gui.Name="ZO_SpectatorHUD";gui.ResetOnSpawn=false;gui.DisplayOrder=7;gui.Parent=playerGui
local panel=Instance.new("Frame");panel.Name="Observer";panel.AnchorPoint=Vector2.new(.5,1)
panel.Position=UDim2.new(.5,0,1,-168);panel.Size=UDim2.fromOffset(440,68);panel.BackgroundColor3=Color3.fromRGB(15,23,27)
panel.BackgroundTransparency=.1;panel.BorderSizePixel=0;panel.Visible=false;panel.Parent=gui
local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,6);corner.Parent=panel
local title=Instance.new("TextLabel");title.Name="Target";title.BackgroundTransparency=1
title.Position=UDim2.fromOffset(48,6);title.Size=UDim2.new(1,-96,0,27);title.Font=Enum.Font.GothamMedium
title.TextSize=14;title.TextColor3=Color3.fromRGB(235,191,108);title.TextTruncate=Enum.TextTruncate.AtEnd;title.Parent=panel
local hint=title:Clone();hint.Name="Hint";hint.Position=UDim2.fromOffset(48,35);hint.Size=UDim2.new(1,-96,0,24)
hint.TextSize=11;hint.TextColor3=Color3.fromRGB(165,184,181);hint.Parent=panel
local function button(name,text,x)
    local b=Instance.new("TextButton");b.Name=name;b.Text=text;b.Font=Enum.Font.GothamBold;b.TextSize=20
    b.TextColor3=Color3.fromRGB(231,238,231);b.BackgroundTransparency=1;b.Position=UDim2.new(x,if x==1 then -42 else 0,0,0)
    b.Size=UDim2.fromOffset(42,68);b.Modal=true;b.Parent=panel;return b
end
local previous=button("Previous","‹",0);local nextButton=button("Next","›",1)
local connections={}
local function connect(signal,fn)local c=signal:Connect(fn);table.insert(connections,c)end
local targetId,targetHum=nil,nil
local ownedCamera,ownedSubject=nil,nil
local savedMin,savedMax=nil,nil
local active=false
local disposed=false
local released=false
local function ownHumanoid()
    return player.Character and player.Character:FindFirstChildOfClass("Humanoid")
end
local function stop()
    if not active then return end
    active=false;targetId=nil;targetHum=nil;panel.Visible=false
    player:SetAttribute("ZO_Spectating",false)
    if ownedCamera and ownedCamera.CameraSubject==ownedSubject and ownedCamera.CameraType~=Enum.CameraType.Scriptable then
        local own=ownHumanoid();if own then ownedCamera.CameraSubject=own end
    end
    if savedMin~=nil and player.CameraMinZoomDistance==8 and player.CameraMaxZoomDistance==20 then
        player.CameraMinZoomDistance=savedMin;player.CameraMaxZoomDistance=savedMax
    end
    savedMin=nil;savedMax=nil;ownedCamera=nil;ownedSubject=nil
end
local function eligible()
    local own=ownHumanoid();local role=if player.Team then player.Team.Name else "Lobby"
    local allowed=State.allowed(role,own~=nil and own.Health>0 and player:GetAttribute("ZO_SpawnPending")~=true,RS:GetAttribute("ZO_RoundState"))
    if not allowed then released=false end
    return allowed and not released,role
end
local function refresh(direction)
    local allowed,role=eligible()
    if not allowed then stop();return end
    local phase=RS:GetAttribute("ZO_RoundState")
    local rows={}
    for _,other in Players:GetPlayers() do
        local char=other.Character;local hum=char and char:FindFirstChildOfClass("Humanoid")
        local root=char and char:FindFirstChild("HumanoidRootPart")
        table.insert(rows,{Id=other.UserId,Player=other,Humanoid=hum,Role=if other.Team then other.Team.Name else "Lobby",
            Alive=hum~=nil and hum.Health>0,Ready=root~=nil and char:IsDescendantOf(workspace) and other:GetAttribute("ZO_SpawnPending")~=true})
    end
    local choices=State.targets(rows,player.UserId,State.side(role,phase))
    local selected=State.pick(choices,targetId,direction)
    if not active then
        active=true;savedMin=player.CameraMinZoomDistance;savedMax=player.CameraMaxZoomDistance
        player.CameraMaxZoomDistance=20;player.CameraMinZoomDistance=8
    end
    player:SetAttribute("ZO_Spectating",true)
    targetId=if selected then selected.Id else nil;targetHum=if selected then selected.Humanoid else nil
    title.Text=if selected then "OBSERVANDO / "..selected.Player.DisplayName else "Aguardando companheiro vivo"
    local at=player:GetAttribute("ZO_RespawnAt")
    local seconds=if type(at)=="number" then math.max(0,math.ceil(at-workspace:GetServerTimeNow())) else nil
    hint.Text=if player:GetAttribute("ZO_SpawnPending")==true then "Retorno aguardando espaço seguro · ← / → trocar"
        elseif seconds then ("Retorno em %ds · ← / → trocar"):format(seconds) else "Próxima rodada · ← / → trocar"
    previous.Visible=#choices>1;nextButton.Visible=#choices>1
end
connect(previous.Activated,function()refresh(-1)end);connect(nextButton.Activated,function()refresh(1)end)
CAS:BindActionAtPriority("ZO_SpectatorCycle",function(_,state,input)
    if state~=Enum.UserInputState.Begin or UIS:GetFocusedTextBox() or not active then return Enum.ContextActionResult.Pass end
    local direction=if input.KeyCode==Enum.KeyCode.Left or input.KeyCode==Enum.KeyCode.ButtonL1 then -1 else 1
    refresh(direction);return Enum.ContextActionResult.Sink
end,false,4000,Enum.KeyCode.Left,Enum.KeyCode.Right,Enum.KeyCode.ButtonL1,Enum.KeyCode.ButtonR1)
local elapsed=0
local renderName="ZO_SpectatorCamera"
Run:UnbindFromRenderStep(renderName)
Run:BindToRenderStep(renderName,Enum.RenderPriority.Camera.Value-3,function(dt)
    if disposed then return end
    local camera=workspace.CurrentCamera
    if not camera then return end
    if camera.CameraType==Enum.CameraType.Scriptable then
        if active then released=true;stop() end
        return
    end
    if active and ownedCamera==camera and ownedSubject and camera.CameraSubject~=ownedSubject and camera.CameraSubject~=ownHumanoid() then
        released=true;stop();return
    end
    elapsed+=dt
    if elapsed>=.1 then elapsed=0;refresh() end
    if not active then return end
    local allowed=eligible();if not allowed then stop();return end
    panel.Size=UDim2.fromOffset(math.min(440,camera.ViewportSize.X-24),68)
    panel.Visible=player:GetAttribute("ZO_ShopOpen")~=true and player:GetAttribute("ZO_TacticalMapOpen")~=true
    if targetHum and targetHum.Health>0 and targetHum.Parent then
        if ownedCamera and ownedCamera~=camera and ownedCamera.CameraSubject==ownedSubject then
            local own=ownHumanoid();if own then ownedCamera.CameraSubject=own end
        end
        camera.CameraSubject=targetHum;ownedCamera=camera;ownedSubject=targetHum
    elseif ownedCamera and ownedCamera.CameraSubject==ownedSubject then
        local own=ownHumanoid();if own then ownedCamera.CameraSubject=own end
        ownedSubject=nil
    end
end)
gui.Destroying:Connect(function()
    disposed=true;stop();player:SetAttribute("ZO_Spectating",false)
    CAS:UnbindAction("ZO_SpectatorCycle");Run:UnbindFromRenderStep(renderName)
    for _,connection in connections do connection:Disconnect() end
end)
