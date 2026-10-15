--!strict
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CAS = game:GetService("ContextActionService")
local player = Players.LocalPlayer
local shared = RS:WaitForChild("K17Barricades")
local Config = require(shared:WaitForChild("Config"))
local Rules = require(shared:WaitForChild("Rules"))
local Placement = require(shared:WaitForChild("Placement"))
local remote = RS:WaitForChild("ZO_BarricadeAction") :: RemoteEvent
local folder = workspace:WaitForChild("ZO_Barricades")
local map = workspace:WaitForChild("ZO_K17Foundry")
local selection: Model? = nil
local ghost: Model? = nil
local quarter = 0
local candidateX,candidateZ = 0,0
local valid = false
local aiming: Model? = nil
local lastPreview = 0
local lastAttack = 0
local holdingAttack = false
local notice,noticeUntil = "",0

local gui = Instance.new("ScreenGui")
gui.Name="ZO_BarricadeHUD";gui.ResetOnSpawn=false;gui.DisplayOrder=5
gui.Parent=player:WaitForChild("PlayerGui")
local panel=Instance.new("TextLabel")
panel.AnchorPoint=Vector2.new(.5,1);panel.Position=UDim2.new(.5,0,1,-110)
panel.Size=UDim2.new(.88,0,0,96);panel.BackgroundColor3=Color3.fromRGB(17,24,27)
panel.BackgroundTransparency=.15;panel.TextColor3=Color3.fromRGB(230,235,219)
panel.Font=Enum.Font.GothamMedium;panel.TextSize=15;panel.TextWrapped=true
panel.Parent=gui
local limit=Instance.new("UISizeConstraint");limit.MaxSize=Vector2.new(650,96);limit.Parent=panel
local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,8);corner.Parent=panel
local cross=Instance.new("TextLabel")
cross.BackgroundTransparency=1;cross.Size=UDim2.fromOffset(30,30)
cross.Position=UDim2.new(.5,-15,.5,-15);cross.Text="+";cross.TextSize=24
cross.Font=Enum.Font.GothamBold;cross.TextColor3=Color3.fromRGB(213,172,106);cross.Parent=gui
local targetHighlight=Instance.new("Highlight")
targetHighlight.FillTransparency=1;targetHighlight.OutlineColor=Color3.fromRGB(222,190,103)
targetHighlight.DepthMode=Enum.HighlightDepthMode.Occluded;targetHighlight.Parent=workspace
task.spawn(function()
    local defenses=map:WaitForChild("DefensePoints")
    local marker=defenses:WaitForChild("07_WarehouseStores")
    local beacon=Instance.new("BillboardGui")
    beacon.Name="StockroomGuide";beacon.Adornee=marker :: BasePart
    beacon.Size=UDim2.fromOffset(180,36);beacon.StudsOffset=Vector3.new(0,9,0)
    beacon.MaxDistance=150;beacon.AlwaysOnTop=false;beacon.Parent=gui
    local title=Instance.new("TextLabel");title.Size=UDim2.fromScale(1,1)
    title.BackgroundColor3=Color3.fromRGB(28,44,38);title.BackgroundTransparency=.2
    title.TextColor3=Color3.fromRGB(224,213,159);title.Text="07 · ESTOQUE DO DEPÓSITO"
    title.Font=Enum.Font.GothamBold;title.TextSize=12;title.Parent=beacon
end)

local function alive(): boolean
    local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    return hum~=nil and hum.Health>0
end
local function phase(): string?
    return Rules.phase(RS:GetAttribute("ZO_RoundState"),RunService:IsStudio(),workspace:GetAttribute("ZO_BarricadePractice")==true,#Players:GetPlayers())
end
local function role(): string?
    return if player.Team then player.Team.Name else nil
end
local function clear()
    if ghost then ghost:Destroy() end
    ghost=nil;selection=nil;valid=false
end
local function ray(): RaycastResult?
    local camera=workspace.CurrentCamera
    if not camera then return nil end
    local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
    local excluded: {Instance}={camera}
    if player.Character then table.insert(excluded,player.Character) end
    if ghost then table.insert(excluded,ghost) end
    params.FilterDescendantsInstances=excluded
    params.RespectCanCollide=true
    local size=camera.ViewportSize
    local aim=camera:ViewportPointToRay(size.X/2,size.Y/2)
    return workspace:Raycast(aim.Origin,aim.Direction*60,params)
end
local function aimed(hit: RaycastResult?): Model?
    if not hit then return nil end
    local model=hit.Instance:FindFirstAncestorOfClass("Model")
    if model and model.Parent==folder and model:GetAttribute("ZO_Destroyed")~=true then return model end
    return nil
end
local function attack()
    if not Rules.canAttack(role(),phase(),alive()) or os.clock()-lastAttack<Config.MeleeCooldown+.03 then return end
    lastAttack=os.clock();remote:FireServer("Attack",aimed(ray()))
end

remote.OnClientEvent:Connect(function(action: string, value: any)
    if action=="Selected" and typeof(value)=="Instance" and value:IsA("Model") and value:IsDescendantOf(folder) then
        clear();selection=value;quarter=value:GetAttribute("ZO_Quarter") or 0
        ghost=value:Clone();ghost.Name="ZO_PlacementPreview"
        for _, item in ghost:GetDescendants() do
            if item:IsA("BasePart") then
                item.CanCollide=false;item.CanQuery=false;item.CanTouch=false;item.CastShadow=false
                item.Transparency=if item.Name=="Hull" then .75 else .4
                item.Material=Enum.Material.ForceField
            end
        end
        ghost.Parent=workspace
        notice="O original continua sólido até confirmar.";noticeUntil=os.clock()+2
    elseif action=="Released" then clear();notice=tostring(value);noticeUntil=os.clock()+2
    elseif action=="Message" then notice=tostring(value);noticeUntil=os.clock()+2
    elseif action=="Hit" then
        notice=if value<=0 then "Barricada destruída!" else ("Impacto! Resistência restante: %d"):format(value)
        noticeUntil=os.clock()+.8
    elseif action=="Miss" then notice="Aproxime-se e mire no objeto com a passagem livre.";noticeUntil=os.clock()+.8 end
end)

local function interact(_, state: Enum.UserInputState): Enum.ContextActionResult
    if state~=Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
    if not Rules.canBuild(role(),phase(),alive()) then return Enum.ContextActionResult.Pass end
    if selection then
        if valid then remote:FireServer("Place",nil,candidateX,candidateZ,quarter)
        else notice="Escolha uma posição livre no piso do estoque.";noticeUntil=os.clock()+2 end
    elseif aiming then remote:FireServer("Select",aiming) end
    return Enum.ContextActionResult.Sink
end
local function rotate(_, state: Enum.UserInputState): Enum.ContextActionResult
    if not selection then return Enum.ContextActionResult.Pass end
    if state==Enum.UserInputState.Begin then quarter=(quarter+1)%4;lastPreview=0 end
    return Enum.ContextActionResult.Sink
end
local function cancel(_, state: Enum.UserInputState): Enum.ContextActionResult
    if not selection then return Enum.ContextActionResult.Pass end
    if state==Enum.UserInputState.Begin then remote:FireServer("Cancel");clear() end
    return Enum.ContextActionResult.Sink
end
local function melee(_, state: Enum.UserInputState): Enum.ContextActionResult
    if not Rules.canAttack(role(),phase(),alive()) then holdingAttack=false;return Enum.ContextActionResult.Pass end
    if state==Enum.UserInputState.Begin then holdingAttack=true;attack()
    elseif state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel then holdingAttack=false end
    return Enum.ContextActionResult.Sink
end
CAS:BindActionAtPriority("ZO_BarricadeUse",interact,true,3000,Enum.KeyCode.E,Enum.KeyCode.ButtonX)
CAS:BindActionAtPriority("ZO_BarricadeRotate",rotate,true,3000,Enum.KeyCode.R,Enum.KeyCode.ButtonY)
CAS:BindActionAtPriority("ZO_BarricadeCancel",cancel,true,3000,Enum.KeyCode.X,Enum.KeyCode.ButtonB)
CAS:BindActionAtPriority("ZO_ZombieMelee",melee,true,3000,Enum.UserInputType.MouseButton1,Enum.KeyCode.ButtonR2)
for name,title in {ZO_BarricadeUse="Mover",ZO_BarricadeRotate="Girar",ZO_BarricadeCancel="Cancelar",ZO_ZombieMelee="Atacar"} do
    CAS:SetTitle(name,title)
end
CAS:SetPosition("ZO_BarricadeUse",UDim2.new(1,-150,1,-170))
CAS:SetPosition("ZO_BarricadeRotate",UDim2.new(1,-235,1,-170))
CAS:SetPosition("ZO_BarricadeCancel",UDim2.new(1,-235,1,-255))
CAS:SetPosition("ZO_ZombieMelee",UDim2.new(1,-150,1,-170))
player.CharacterRemoving:Connect(function() clear();holdingAttack=false end)
player:GetPropertyChangedSignal("Team"):Connect(function() clear();holdingAttack=false end)

RunService.RenderStepped:Connect(function()
    if holdingAttack then attack() end
    if os.clock()-lastPreview<.1 then return end
    lastPreview=os.clock()
    local build=Rules.canBuild(role(),phase(),alive())
    local zombie=Rules.canAttack(role(),phase(),alive())
    if not build and selection then clear() end
    local hit=ray();aiming=aimed(hit)
    targetHighlight.Adornee=if build or zombie then aiming else nil
    targetHighlight.Enabled=aiming~=nil and (build or zombie)
    local description=""
    if aiming then
        description=("%s · %d / %d"):format(aiming:GetAttribute("ZO_Label") or aiming.Name,aiming:GetAttribute("ZO_Health") or 0,aiming:GetAttribute("ZO_MaxHealth") or 0)
    end
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if selection and ghost and root and root:IsA("BasePart") then
        local camera=workspace.CurrentCamera
        if not camera then return end
        -- Camera-centre direction projected onto the fixed ground. No client-supplied height.
        local view=camera:ViewportPointToRay(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
        local t=if view.Direction.Y<-.05 then (Config.Zone.Floor-view.Origin.Y)/view.Direction.Y else -1
        local flat=Vector3.new(view.Direction.X,0,view.Direction.Z)
        local point=if t>0 and t<60 then view.Origin+view.Direction*t
            else root.Position+(if flat.Magnitude>.01 then flat.Unit else Vector3.new(0,0,-1))*6
        candidateX=math.round(point.X*2)/2;candidateZ=math.round(point.Z*2)/2
        local kind=Config.Kinds[selection:GetAttribute("ZO_Kind")]
        local cf=CFrame.new(candidateX,Config.Zone.Floor+kind.Height/2,candidateZ)*CFrame.Angles(0,quarter*math.pi/2,0)
        ghost:PivotTo(cf)
        local policy,why=Rules.candidate(Config.Zone,kind,candidateX,candidateZ,quarter,root.Position.X,root.Position.Y,root.Position.Z,Config.PlacementRange)
        local hull=selection:FindFirstChild("Hull") :: BasePart
        valid=policy
        if valid then valid,why=Placement.clear(selection,cf,hull.Size,map) end
        if valid and not Placement.sweep(selection,hull,cf,quarter,map,folder) then valid=false;why="Trajeto ou rotação obstruídos." end
        for _,part in ghost:GetDescendants() do
            if part:IsA("BasePart") then part.Color=if valid then Color3.fromRGB(95,220,145) else Color3.fromRGB(235,95,75) end
        end
        panel.Text=("%s\nE: posicionar · R: girar 90° · X: cancelar\n%s"):format(kind.Label,if valid then "Posição livre. A arma fica guardada durante a seleção." else why)
    elseif zombie then
        panel.Text="ZUMBI — Clique / RT: golpear barricada\n"..description.."\n"..(if os.clock()<noticeUntil then notice else "Destrua a defesa ou procure o acesso pela sala vizinha.")
    elseif build and aiming then
        panel.Text=description.."\nE: selecionar e reposicionar · Mire no chão para escolher a posição.\n"..(if os.clock()<noticeUntil then notice else "Os objetos são destrutíveis; proteja também a entrada lateral.")
    else
        local distance=if root and root:IsA("BasePart") then (root.Position-Vector3.new(-238,4,123)).Magnitude else 0
        panel.Text=("ESTOQUE DO DEPÓSITO · esconderijo 07 · %.0f studs\nArmários, mesa e caixas disponíveis no térreo.\n%s"):format(distance,if os.clock()<noticeUntil then notice else "Prepare a defesa antes da infecção.")
    end
    panel.Visible=(build and (selection~=nil or aiming~=nil or phase()=="Preparation" or os.clock()<noticeUntil)) or (zombie and (aiming~=nil or os.clock()<noticeUntil))
    cross.Visible=zombie or selection~=nil or (build and RS:GetAttribute("ZO_RoundState")~="Active")
    for name,show in {ZO_BarricadeUse=build,ZO_BarricadeRotate=selection~=nil,ZO_BarricadeCancel=selection~=nil,ZO_ZombieMelee=zombie} do
        local button=CAS:GetButton(name)
        if button then button.Visible=show end
    end
end)
