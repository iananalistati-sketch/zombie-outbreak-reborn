--!strict
-- One trigger drives the rifle for humans and melee for zombies. Server decides hits.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local CAS=game:GetService("ContextActionService")
local GuiService=game:GetService("GuiService")
local Debris=game:GetService("Debris")
local player=Players.LocalPlayer
local shared=RS:WaitForChild("K17Gameplay")
local Config=require(shared.Config)
local Rules=require(shared.Rules)
local rifle=RS:WaitForChild("ZO_FireRifle") :: RemoteEvent
local melee=RS:WaitForChild("ZO_Melee") :: RemoteEvent
local effects=RS:WaitForChild("ZO_CombatFX") :: RemoteEvent
local held=false
local nextAction=0
local hitUntil=0
local swingUntil=0
local recoil=0
local notice,noticeUntil="",0
local practiceOrigin: Vector3?=nil
local practiceTarget: Vector3?=nil
local practiceDeadline=0
local gui=Instance.new("ScreenGui")
gui.Name="ZO_WeaponHUD";gui.ResetOnSpawn=false;gui.Parent=player:WaitForChild("PlayerGui")
local function label(name: string,position: UDim2,size: UDim2,textSize: number): TextLabel
    local item=Instance.new("TextLabel")
    item.Name=name;item.Position=position;item.Size=size;item.TextSize=textSize
    item.Font=Enum.Font.RobotoMono;item.BackgroundTransparency=1
    item.TextColor3=Color3.fromRGB(232,219,182);item.TextStrokeTransparency=.5
    item.Parent=gui;return item
end
local ammo=label("Ammo",UDim2.new(1,-280,1,-80),UDim2.fromOffset(260,48),22)
local health=label("Health",UDim2.new(0,20,1,-80),UDim2.fromOffset(240,48),22)
local cross=label("Crosshair",UDim2.new(.5,-15,.5,-15),UDim2.fromOffset(30,30),24)
local status=label("Feedback",UDim2.new(.5,-250,1,-130),UDim2.fromOffset(500,36),15)
status.TextWrapped=true
local vm=Instance.new("Model");vm.Name="ZO_LocalWeapon";vm.Parent=workspace.CurrentCamera
local function part(name: string,size: Vector3,offset: CFrame,color: Color3,weapon: string)
    local obj=Instance.new("Part");obj.Name=name;obj.Size=size
    obj.Material=if weapon=="Claws" then Enum.Material.SmoothPlastic else Enum.Material.Metal;obj.Color=color
    obj.Anchored=true;obj.CanCollide=false;obj.CanQuery=false;obj.CanTouch=false;obj.CastShadow=false
    obj:SetAttribute("Offset",offset);obj:SetAttribute("Weapon",weapon);obj.Parent=vm
end
-- Original placeholder models. No Counter-Strike art/animations were imported.
part("Receiver",Vector3.new(.54,.48,2.2),CFrame.new(.62,-.63,-1.85),Color3.fromRGB(48,53,51),"Rifle")
part("Barrel",Vector3.new(.15,.15,1.6),CFrame.new(.62,-.5,-3.45),Color3.fromRGB(27,31,30),"Rifle")
part("Stock",Vector3.new(.4,.4,1),CFrame.new(.62,-.74,-.45),Color3.fromRGB(62,64,56),"Rifle")
part("Magazine",Vector3.new(.32,.8,.5),CFrame.new(.62,-1.05,-1.85),Color3.fromRGB(35,39,37),"Rifle")
part("Sight",Vector3.new(.14,.17,.3),CFrame.new(.62,-.31,-2.1),Color3.fromRGB(17,20,19),"Rifle")
for _,side in {-1,1} do
    part("Hand",Vector3.new(.5,.3,.75),CFrame.new(side*.73,-.9,-1.5)*CFrame.Angles(0,side*.25,0),Color3.fromRGB(112,130,104),"Claws")
    for finger=-1,1 do
        part("Claw",Vector3.new(.1,.1,.55),CFrame.new(side*.73+finger*.15,-.84,-2.05),Color3.fromRGB(99,94,70),"Claws")
    end
end
local function role(): string?
    return player.Team and player.Team.Name
end
local function phase(): string?
    return Rules.phase(RS:GetAttribute("ZO_RoundState"),RunService:IsStudio(),workspace:GetAttribute("ZO_BarricadePractice")==true,#Players:GetPlayers())
end
local function humanoid(): Humanoid?
    return player.Character and player.Character:FindFirstChildOfClass("Humanoid")
end
local function canShoot(): boolean
    if player:GetAttribute("ZO_TacticalMapOpen")==true then return false end
    local hum=humanoid()
    return Rules.canFire(role(),phase(),hum~=nil and hum.Health>0,player:GetAttribute("ZO_BarricadeSelection")~=nil)
end
local function canMelee(): boolean
    if player:GetAttribute("ZO_TacticalMapOpen")==true then return false end
    local hum=humanoid()
    return Rules.canMelee(role(),phase(),hum~=nil and hum.Health>0)
end
local function action()
    local camera=workspace.CurrentCamera
    if not camera or UIS:GetFocusedTextBox() or os.clock()<nextAction then return end
    if canShoot() and player:GetAttribute("ZO_Reloading")~=true and (player:GetAttribute("ZO_Ammo") or 0)>0 then
        nextAction=os.clock()+Config.Rifle.FireInterval+.005
        rifle:FireServer("Fire",camera.CFrame.LookVector)
        recoil=math.min(recoil+.08,.22)
        camera.CFrame*=CFrame.Angles(math.rad(.3),0,0)
    elseif canMelee() then
        nextAction=os.clock()+Config.Melee.Cooldown+.02
        swingUntil=os.clock()+.24
        melee:FireServer(camera.CFrame.LookVector)
    end
end
local function trigger(_,state: Enum.UserInputState): Enum.ContextActionResult
    if state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel then held=false;return Enum.ContextActionResult.Pass end
    if not canShoot() and not canMelee() then return Enum.ContextActionResult.Pass end
    if state==Enum.UserInputState.Begin then held=true;action() end
    return Enum.ContextActionResult.Sink
end
local function reload(_,state: Enum.UserInputState): Enum.ContextActionResult
    if not canShoot() then return Enum.ContextActionResult.Pass end
    if state==Enum.UserInputState.Begin then rifle:FireServer("Reload") end
    return Enum.ContextActionResult.Sink
end
CAS:BindActionAtPriority("ZO_Trigger",trigger,true,2200,Enum.UserInputType.MouseButton1,Enum.KeyCode.ButtonR2)
CAS:BindActionAtPriority("ZO_Reload",reload,true,2200,Enum.KeyCode.R,Enum.KeyCode.ButtonX)
CAS:SetTitle("ZO_Trigger","Atacar");CAS:SetPosition("ZO_Trigger",UDim2.new(1,-150,1,-170))
CAS:SetTitle("ZO_Reload","Recarregar");CAS:SetPosition("ZO_Reload",UDim2.new(1,-235,1,-170))
local function stop() held=false;nextAction=0;recoil=0 end
player:GetAttributeChangedSignal("ZO_TacticalMapOpen"):Connect(function()
    if player:GetAttribute("ZO_TacticalMapOpen")==true then stop() end
end)
UIS.WindowFocusReleased:Connect(stop);UIS.TextBoxFocused:Connect(stop);GuiService.MenuOpened:Connect(stop)
player.CharacterRemoving:Connect(stop);player:GetPropertyChangedSignal("Team"):Connect(stop)
RS:GetAttributeChangedSignal("ZO_RoundState"):Connect(function()
    if phase()~="Active" and phase()~="Preparation" then stop() end
end)
rifle.OnClientEvent:Connect(function(kind: string)
    if kind=="Hit" then hitUntil=os.clock()+.12 end
end)
melee.OnClientEvent:Connect(function(kind: string,value: any)
    if kind=="Infected" then notice="INFECÇÃO";hitUntil=os.clock()+.2
    elseif kind=="Barricade" then notice=if value<=0 then "Objeto destruído" else ("Resistência: %d"):format(value);hitUntil=os.clock()+.12
    else notice="" end
    noticeUntil=os.clock()+1
end)
effects.OnClientEvent:Connect(function(kind: string,origin: any,destination: any,_shooter: any)
    if kind=="PracticeAim" and RunService:IsStudio() and typeof(origin)=="Vector3" and typeof(destination)=="Vector3" then
        practiceOrigin=origin;practiceTarget=destination;practiceDeadline=os.clock()+3;return
    end
    if kind~="Shot" or typeof(origin)~="Vector3" or typeof(destination)~="Vector3" then return end
    local distance=(destination-origin).Magnitude
    if distance<.1 then return end
    -- Short-lived, query-free trace. No projectile physics or external asset IDs.
    local trace=Instance.new("Part");trace.Name="ZO_ShotTrace"
    trace.Size=Vector3.new(.035,.035,distance);trace.CFrame=CFrame.lookAt((origin+destination)/2,destination)
    trace.Anchored=true;trace.CanCollide=false;trace.CanQuery=false;trace.CanTouch=false;trace.CastShadow=false
    trace.Material=Enum.Material.Neon;trace.Color=Color3.fromRGB(226,194,124);trace.Transparency=.45
    trace.Parent=workspace;Debris:AddItem(trace,.045)
end)
RunService.RenderStepped:Connect(function(dt)
    if held then action() end
    local camera=workspace.CurrentCamera
    if not camera then return end
    if practiceOrigin and practiceTarget then
        local head=player.Character and player.Character:FindFirstChild("Head")
        if head and head:IsA("BasePart") and (head.Position-practiceOrigin).Magnitude<3 then
            camera.CFrame=CFrame.lookAt(head.Position,practiceTarget);practiceOrigin=nil;practiceTarget=nil
        elseif os.clock()>practiceDeadline then practiceOrigin=nil;practiceTarget=nil end
    end
    if vm.Parent~=camera then vm.Parent=camera end
    local gun,zombie=canShoot(),canMelee()
    local hum=humanoid()
    local active=gun or zombie
    local firstPerson=active or (phase()=="Preparation" and role()=="Humans" and hum~=nil and hum.Health>0)
    player.CameraMode=if firstPerson then Enum.CameraMode.LockFirstPerson else Enum.CameraMode.Classic
    local reloading=player:GetAttribute("ZO_Reloading")==true
    local remaining=math.max(0,(player:GetAttribute("ZO_ReloadEndsAt") or 0)-workspace:GetServerTimeNow())
    local reloadPose=if reloading then CFrame.new(0,-.3,.2)*CFrame.Angles(-.4,0,-.2) else CFrame.identity
    local swing=math.max(0,(swingUntil-os.clock())/.24)
    for _,obj in vm:GetChildren() do
        if obj:IsA("BasePart") then
            local riflePart=obj:GetAttribute("Weapon")=="Rifle"
            obj.LocalTransparencyModifier=if (riflePart and gun) or (not riflePart and zombie) then 0 else 1
            obj.CFrame=camera.CFrame*(if riflePart then reloadPose*CFrame.new(0,0,recoil) else CFrame.new(0,swing*.14,-swing*.45))*(obj:GetAttribute("Offset") :: CFrame)
        end
    end
    recoil*=math.exp(-dt*16)
    ammo.Visible=gun;health.Visible=active;cross.Visible=active
    local clip=player:GetAttribute("ZO_Ammo") or 0
    ammo.Text=if reloading then ("RECARREGANDO  %.1fs"):format(remaining) else ("FUZIL  %02d / %03d"):format(clip,player:GetAttribute("ZO_Reserve") or 0)
    health.Text=("%s  %d"):format(if zombie then "ZUMBI" else "VIDA",math.ceil(if hum then hum.Health else 0))
    cross.Text=if os.clock()<hitUntil then "×" else "+"
    cross.TextColor3=if zombie then Color3.fromRGB(211,128,101) else Color3.fromRGB(230,222,192)
    status.Text=if os.clock()<noticeUntil then notice elseif gun and clip==0 then "R: recarregar"
        elseif zombie then "Clique: atacar e infectar" else ""
    status.Visible=active
    local triggerButton=CAS:GetButton("ZO_Trigger")
    if triggerButton then triggerButton.Visible=active end
    local reloadButton=CAS:GetButton("ZO_Reload")
    if reloadButton then reloadButton.Visible=gun end
end)
