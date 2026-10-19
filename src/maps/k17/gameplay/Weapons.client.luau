--!strict
-- Original procedural viewmodels; authoritative hits, inventory and ammunition live on the server.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local CAS=game:GetService("ContextActionService")
local GuiService=game:GetService("GuiService")
local Debris=game:GetService("Debris")
local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui") :: PlayerGui
local shared=RS:WaitForChild("K17Gameplay")
local Config=require(shared.Config)
local Rules=require(shared.Rules)
local rifle=RS:WaitForChild("ZO_FireRifle") :: RemoteEvent
local melee=RS:WaitForChild("ZO_Melee") :: RemoteEvent
local effects=RS:WaitForChild("ZO_CombatFX") :: RemoteEvent
local loadout=RS:WaitForChild("ZO_LoadoutAction") :: RemoteEvent
local held=false
local nextAction=0
local hitUntil=0
local hitHead=false
local swingUntil=0
local flashUntil=0
local recoil=0
local notice,noticeUntil="",0
local practiceOrigin: Vector3?=nil
local practiceTarget: Vector3?=nil
local practiceDeadline=0
local gui=Instance.new("ScreenGui")
gui.Name="ZO_WeaponHUD";gui.ResetOnSpawn=false;gui.Parent=playerGui
local function label(name: string,position: UDim2,size: UDim2,textSize: number): TextLabel
    local item=Instance.new("TextLabel")
    item.Name=name;item.Position=position;item.Size=size;item.TextSize=textSize
    item.Font=Enum.Font.RobotoMono;item.BackgroundTransparency=1
    item.TextColor3=Color3.fromRGB(232,219,182);item.TextStrokeTransparency=.5
    item.Parent=gui;return item
end
local ammo=label("Ammo",UDim2.new(1,-330,1,-82),UDim2.fromOffset(310,48),19)
local health=label("Health",UDim2.new(0,20,1,-82),UDim2.fromOffset(200,48),21)
local cross=label("Crosshair",UDim2.new(.5,-15,.5,-15),UDim2.fromOffset(30,30),24)
local status=label("Feedback",UDim2.new(.5,-250,1,-126),UDim2.fromOffset(500,36),14)
status.TextWrapped=true
local vm=Instance.new("Model");vm.Name="ZO_LocalWeapon";vm.Parent=workspace.CurrentCamera
local parts: {{Object: Part,Offset: CFrame,Weapon: string,Flash: boolean}}={}
local function part(name: string,size: Vector3,offset: CFrame,color: Color3,weapon: string,flash: boolean?)
    local obj=Instance.new("Part");obj.Name=weapon..name;obj.Size=size
    obj.Material=if flash then Enum.Material.Neon elseif weapon=="Claws" then Enum.Material.SmoothPlastic else Enum.Material.Metal
    obj.Color=color
    obj.Anchored=true;obj.CanCollide=false;obj.CanQuery=false;obj.CanTouch=false;obj.CastShadow=false
    obj.Transparency=1 -- A new model is hidden until its first camera update.
    obj.Parent=vm
    table.insert(parts,{Object=obj,Offset=offset,Weapon=weapon,Flash=flash==true})
end
local steel=Color3.fromRGB(43,49,50)
local dark=Color3.fromRGB(24,29,29)
local function gunPart(id: string,name: string,x: number,y: number,z: number,sx: number,sy: number,sz: number,color: Color3?)
    part(name,Vector3.new(sx,sy,sz),CFrame.new(x,y,z),color or steel,id)
end
-- Distinct silhouettes rather than five recolours of one rifle. No imported weapon art.
gunPart("Rifle","Receiver",.62,-.63,-1.85,.48,.42,1.85)
gunPart("Rifle","Barrel",.62,-.5,-3.12,.12,.12,1.05,dark)
gunPart("Rifle","Stock",.62,-.7,-.65,.36,.35,.72)
gunPart("Rifle","Magazine",.62,-1.02,-1.8,.28,.7,.46,dark)
gunPart("Rifle","Rail",.62,-.36,-1.85,.13,.13,1.1,dark)
gunPart("SMG","Receiver",.58,-.65,-1.65,.4,.43,1.25)
gunPart("SMG","Suppressor",.58,-.53,-2.65,.22,.22,.75,dark)
gunPart("SMG","Grip",.58,-.99,-1.42,.26,.5,.3,dark)
gunPart("SMG","Magazine",.58,-1.08,-1.94,.21,.85,.27)
gunPart("SMG","FoldedStock",.72,-.63,-.69,.1,.18,.62,dark)
gunPart("Shotgun","Receiver",.62,-.68,-1.5,.46,.4,1.12)
gunPart("Shotgun","Barrel",.62,-.51,-3,.18,.18,1.8,dark)
gunPart("Shotgun","Tube",.62,-.73,-2.87,.15,.15,1.45)
gunPart("Shotgun","Pump",.62,-.73,-2.28,.35,.3,.65,Color3.fromRGB(103,76,48))
gunPart("Shotgun","Stock",.62,-.79,-.53,.37,.4,.85,Color3.fromRGB(103,76,48))
gunPart("LMG","Receiver",.65,-.64,-1.85,.62,.51,1.8)
gunPart("LMG","HeavyBarrel",.65,-.5,-3.3,.22,.22,1.2,dark)
gunPart("LMG","AmmoBox",.84,-1.03,-1.82,.9,.7,.72,Color3.fromRGB(73,77,55))
gunPart("LMG","Handle",.65,-.29,-1.65,.16,.15,.65,dark)
gunPart("LMG","BipodLeft",.41,-.79,-2.94,.08,.47,.1,dark)
gunPart("LMG","BipodRight",.89,-.79,-2.94,.08,.47,.1,dark)
gunPart("Pistol","Slide",.48,-.64,-1.48,.32,.32,.98)
gunPart("Pistol","Grip",.48,-.97,-1.13,.29,.55,.34,dark)
gunPart("Pistol","FrontSight",.48,-.43,-1.85,.07,.09,.08,dark)
local muzzleZ={Rifle=-3.69,SMG=-3.07,Shotgun=-3.96,LMG=-3.96,Pistol=-2.03}
for _,id in Config.WeaponOrder do
    local weapon=Config.Weapons[id]
    local x=if id=="Pistol" then .48 elseif id=="SMG" then .58 elseif id=="LMG" then .65 else .62
    part("MuzzleFlash",Vector3.new(.23,.23,.35),CFrame.new(x,-.51,muzzleZ[id]),Color3.fromRGB(255,209,111),id,true)
    gunPart(id,"GripAccent",x+.01,-.69,if id=="Pistol" then -1.32 else -1.55,.035,.15,.23,Color3.fromRGB(weapon.Color[1],weapon.Color[2],weapon.Color[3]))
end
for _,side in {-1,1} do
    part("Hand",Vector3.new(.5,.3,.75),CFrame.new(side*.73,-.9,-1.5)*CFrame.Angles(0,side*.25,0),Color3.fromRGB(112,130,104),"Claws")
    for finger=-1,1 do
        part("Claw",Vector3.new(.1,.1,.55),CFrame.new(side*.73+finger*.15,-.84,-2.05),Color3.fromRGB(99,94,70),"Claws")
    end
end
local function role(): string? return player.Team and player.Team.Name end
local function phase(): string?
    return Rules.phase(RS:GetAttribute("ZO_RoundState"),RunService:IsStudio(),workspace:GetAttribute("ZO_BarricadePractice")==true,#Players:GetPlayers())
end
local function humanoid(): Humanoid? return player.Character and player.Character:FindFirstChildOfClass("Humanoid") end
local function weapon()
    return Config.Weapons[player:GetAttribute("ZO_WeaponId")] or Config.Weapons.Rifle
end
local function menuOpen(): boolean
    return player:GetAttribute("ZO_ShopOpen")==true or player:GetAttribute("ZO_TacticalMapOpen")==true or GuiService.MenuIsOpen
end
local function canShoot(): boolean
    if menuOpen() then return false end
    local hum=humanoid()
    return Rules.canFire(role(),phase(),hum~=nil and hum.Health>0,player:GetAttribute("ZO_BarricadeSelection")~=nil)
end
local function canMelee(): boolean
    if menuOpen() then return false end
    local hum=humanoid()
    return Rules.canMelee(role(),phase(),hum~=nil and hum.Health>0)
end
local function stop() held=false;nextAction=0;recoil=0;flashUntil=0 end
local function action()
    local camera=workspace.CurrentCamera
    if not camera or UIS:GetFocusedTextBox() or menuOpen() or os.clock()<nextAction then return end
    local equipped=weapon()
    if canShoot() and player:GetAttribute("ZO_Reloading")~=true and (player:GetAttribute("ZO_Ammo") or 0)>0
        and workspace:GetServerTimeNow()>=(player:GetAttribute("ZO_EquipReadyAt") or 0) then
        nextAction=os.clock()+equipped.FireInterval+.005
        rifle:FireServer("Fire",camera.CFrame.LookVector)
        flashUntil=os.clock()+.045
        recoil=math.min(recoil+.08*equipped.Recoil,.32)
        camera.CFrame*=CFrame.Angles(math.rad(.3*equipped.Recoil),0,0)
    elseif canMelee() then
        nextAction=os.clock()+Config.Melee.Cooldown+.02
        swingUntil=os.clock()+.24
        melee:FireServer(camera.CFrame.LookVector)
    end
end
local function overButton(): boolean
    local point=UIS:GetMouseLocation()
    for _,object in playerGui:GetGuiObjectsAtPosition(point.X,point.Y) do
        local current: Instance?=object
        while current and current~=playerGui do
            if current:IsA("GuiButton") then return true end
            current=current.Parent
        end
    end
    return false
end
local function trigger(_,state: Enum.UserInputState,input: InputObject): Enum.ContextActionResult
    if state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel then held=false;return Enum.ContextActionResult.Pass end
    if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
    if not canShoot() and not canMelee() then return Enum.ContextActionResult.Pass end
    if state==Enum.UserInputState.Begin then
        if input.UserInputType==Enum.UserInputType.MouseButton1 and overButton() then return Enum.ContextActionResult.Pass end
        held=true;action()
    end
    return Enum.ContextActionResult.Sink
end
local function reload(_,state: Enum.UserInputState): Enum.ContextActionResult
    if not canShoot() or UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
    if state==Enum.UserInputState.Begin then stop();rifle:FireServer("Reload") end
    return Enum.ContextActionResult.Sink
end
local function equip(_,state: Enum.UserInputState,input: InputObject): Enum.ContextActionResult
    if role()~="Humans" or menuOpen() or UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
    local hum=humanoid()
    if not hum or hum.Health<=0 or (phase()~="Preparation" and phase()~="Active") then return Enum.ContextActionResult.Pass end
    if state==Enum.UserInputState.Begin then
        stop()
        local slot=if input.KeyCode==Enum.KeyCode.One then "Primary" elseif input.KeyCode==Enum.KeyCode.Two then "Secondary"
            elseif player:GetAttribute("ZO_WeaponId")==player:GetAttribute("ZO_SecondaryWeapon") then "Primary" else "Secondary"
        loadout:FireServer("Equip",slot)
    end
    return Enum.ContextActionResult.Sink
end
CAS:BindActionAtPriority("ZO_Trigger",trigger,true,2200,Enum.UserInputType.MouseButton1,Enum.KeyCode.ButtonR2)
CAS:BindActionAtPriority("ZO_Reload",reload,true,2200,Enum.KeyCode.R,Enum.KeyCode.ButtonX)
CAS:BindActionAtPriority("ZO_Equip",equip,false,2200,Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Q,Enum.KeyCode.ButtonY)
CAS:SetTitle("ZO_Trigger","Atacar");CAS:SetPosition("ZO_Trigger",UDim2.new(1,-150,1,-170))
CAS:SetTitle("ZO_Reload","Recarregar");CAS:SetPosition("ZO_Reload",UDim2.new(1,-235,1,-170))
for _,name in {"ZO_TacticalMapOpen","ZO_ShopOpen"} do
    player:GetAttributeChangedSignal(name):Connect(function() if menuOpen() then stop() end end)
end
player:GetAttributeChangedSignal("ZO_WeaponId"):Connect(stop)
UIS.WindowFocusReleased:Connect(stop);UIS.TextBoxFocused:Connect(stop);GuiService.MenuOpened:Connect(stop)
player.CharacterRemoving:Connect(stop);player:GetPropertyChangedSignal("Team"):Connect(stop)
RS:GetAttributeChangedSignal("ZO_RoundState"):Connect(function()
    if phase()~="Active" and phase()~="Preparation" then stop() end
end)
rifle.OnClientEvent:Connect(function(kind: string,_damage: any,hitgroup: any)
    if kind=="Hit" then hitUntil=os.clock()+.14;hitHead=hitgroup=="Head"
    elseif kind=="PropHit" then
        notice="Barricada atingida";noticeUntil=os.clock()+.6
    end
end)
melee.OnClientEvent:Connect(function(kind: string,value: any)
    if kind=="Infected" then notice="INFECÇÃO";hitUntil=os.clock()+.2;hitHead=false
    elseif kind=="Barricade" then notice=if value<=0 then "Objeto destruído" else ("Resistência: %d"):format(value);hitUntil=os.clock()+.12;hitHead=false
    else notice="" end
    noticeUntil=os.clock()+1
end)
effects.OnClientEvent:Connect(function(kind: string,origin: any,destination: any,_shooter: any,weaponId: any)
    if kind=="PracticeAim" and RunService:IsStudio() and typeof(origin)=="Vector3" and typeof(destination)=="Vector3" then
        practiceOrigin=origin;practiceTarget=destination;practiceDeadline=os.clock()+3;return
    end
    if kind~="Shot" or typeof(origin)~="Vector3" or typeof(destination)~="Vector3" then return end
    local distance=(destination-origin).Magnitude
    if distance<.1 then return end
    -- Query-free, short-lived trace; it never participates in hit detection.
    local shotWeapon=Config.Weapons[weaponId] or Config.Weapons.Rifle
    local color=shotWeapon.Color
    local trace=Instance.new("Part");trace.Name="ZO_ShotTrace"
    trace.Size=Vector3.new(.035,.035,distance);trace.CFrame=CFrame.lookAt((origin+destination)/2,destination)
    trace.Anchored=true;trace.CanCollide=false;trace.CanQuery=false;trace.CanTouch=false;trace.CastShadow=false
    trace.Material=Enum.Material.Neon;trace.Color=Color3.fromRGB(color[1],color[2],color[3]);trace.Transparency=.4
    trace.Parent=workspace;Debris:AddItem(trace,.045)
end)
RunService.RenderStepped:Connect(function(dt)
    if held and (canMelee() or weapon().Automatic) then action() end
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
    local alive=hum~=nil and hum.Health>0
    local firstPerson=not menuOpen() and alive and ((role()=="Humans" and (phase()=="Preparation" or phase()=="Active")) or zombie)
    player.CameraMode=if firstPerson then Enum.CameraMode.LockFirstPerson else Enum.CameraMode.Classic
    local equipped=weapon()
    local narrow=camera.ViewportSize.X<620
    ammo.TextSize=if narrow then 14 else 19
    ammo.Position=if narrow and UIS.TouchEnabled then UDim2.new(1,-275,1,-198) elseif narrow then UDim2.new(1,-275,1,-82) else UDim2.new(1,-330,1,-82)
    ammo.Size=UDim2.fromOffset(if narrow then 255 else 310,48)
    health.TextSize=if narrow then 17 else 21
    health.Position=if UIS.TouchEnabled then UDim2.new(0,20,1,-153) elseif narrow then UDim2.new(0,12,1,-126) else UDim2.new(0,20,1,-82)
    status.Position=if narrow and UIS.TouchEnabled then UDim2.new(.05,0,1,-240) elseif narrow then UDim2.new(.05,0,1,-202) else UDim2.new(.5,-250,1,-126)
    status.Size=if narrow then UDim2.new(.9,0,0,36) else UDim2.fromOffset(500,36)
    local reloading=player:GetAttribute("ZO_Reloading")==true
    local remaining=math.max(0,(player:GetAttribute("ZO_ReloadEndsAt") or 0)-workspace:GetServerTimeNow())
    local equipping=workspace:GetServerTimeNow()<(player:GetAttribute("ZO_EquipReadyAt") or 0)
    local reloadPose=if reloading then CFrame.new(0,-.3,.2)*CFrame.Angles(-.4,0,-.2) elseif equipping then CFrame.new(0,-.24,.15) else CFrame.identity
    local swing=math.max(0,(swingUntil-os.clock())/.24)
    for _,entry in parts do
        local obj=entry.Object
        local gunPartVisible=entry.Weapon==equipped.Id and gun
        local visible=(gunPartVisible or (entry.Weapon=="Claws" and zombie)) and (not entry.Flash or os.clock()<flashUntil)
        obj.Transparency=if visible then 0 else 1
        obj.CFrame=camera.CFrame*(if entry.Weapon=="Claws" then CFrame.new(0,swing*.14,-swing*.45) else reloadPose*CFrame.new(0,0,recoil))*entry.Offset
    end
    recoil*=math.exp(-dt*16)
    ammo.Visible=gun;health.Visible=active;cross.Visible=active
    local clip=player:GetAttribute("ZO_Ammo") or 0
    ammo.Text=if reloading then ("RECARREGANDO  %.1fs"):format(remaining)
        elseif equipping then "EQUIPANDO..."
        else ("%s  %02d/%d  |  %03d"):format(string.upper(equipped.Label),clip,equipped.Magazine,player:GetAttribute("ZO_Reserve") or 0)
    health.Text=("%s  %d"):format(if zombie then "ZUMBI" else "VIDA",math.ceil(if hum then hum.Health else 0))
    cross.Text=if os.clock()<hitUntil then "×" else "+"
    cross.TextColor3=if os.clock()<hitUntil and hitHead then Color3.fromRGB(255,109,91) elseif zombie then Color3.fromRGB(211,128,101) else Color3.fromRGB(230,222,192)
    status.Text=if os.clock()<noticeUntil then notice elseif gun and clip==0 then "R: recarregar · 1 / 2: trocar arma"
        elseif zombie then "Segure atacar para golpear e infectar" else ""
    status.Visible=active
    local triggerButton=CAS:GetButton("ZO_Trigger")
    if triggerButton then triggerButton.Visible=active end
    local reloadButton=CAS:GetButton("ZO_Reload")
    if reloadButton then reloadButton.Visible=gun end
end)
