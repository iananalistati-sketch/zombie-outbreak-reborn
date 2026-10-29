--!strict
-- Imported Tools provide meshes, sounds, grips and animations for every firearm.
-- Inventory, ammunition, cadence, damage and all hit decisions stay on the server.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local CAS=game:GetService("ContextActionService")
local GuiService=game:GetService("GuiService")
local Debris=game:GetService("Debris")
local ContentProvider=game:GetService("ContentProvider")
local StarterGui=game:GetService("StarterGui")
local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui") :: PlayerGui
local shared=RS:WaitForChild("K17Gameplay")
local Config=require(shared.Config)
local Rules=require(shared.Rules)
local Presentation=require(shared:WaitForChild("WeaponPresentation"))
local PresentationConfig=require(shared:WaitForChild("PresentationConfig"))
local rifle=RS:WaitForChild("ZO_FireRifle") :: RemoteEvent
local melee=RS:WaitForChild("ZO_Melee") :: RemoteEvent
local effects=RS:WaitForChild("ZO_CombatFX") :: RemoteEvent
local loadout=RS:WaitForChild("ZO_LoadoutAction") :: RemoteEvent
local connections: {RBXScriptConnection}={}
local assetConnections: {RBXScriptConnection}={}
local characterConnections: {RBXScriptConnection}={}
local disposed=false
local function connect(signal: RBXScriptSignal,callback: any)
    table.insert(connections,signal:Connect(callback))
end
local function disconnectAll(items: {RBXScriptConnection})
    for _,connection in items do connection:Disconnect() end
    table.clear(items)
end
-- Slots 1/2/Q remain server-controlled, including on devices with a backpack UI.
task.spawn(function()
    for _=1,5 do
        if disposed then return end
        if pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false) end) then return end
        task.wait(.5)
    end
end)
for _,old in playerGui:GetChildren() do
    if old.Name=="ZO_WeaponHUD" or old.Name=="ZO_RifleHUD" then old:Destroy() end
end
local function clearOldModels(camera: Camera?)
    if not camera then return end
    for _,item in camera:GetChildren() do
        if item.Name=="ZO_LocalWeapon" or item.Name=="ZO_LocalReusedRifle" or item.Name=="ZO_FirstPersonArms" then item:Destroy() end
    end
end
clearOldModels(workspace.CurrentCamera)
player:SetAttribute("ZO_ReusedWeaponAssetsStatus",nil)
player:SetAttribute("ZO_WeaponAssetsStatus","Loading")
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
local cross=label("Hitmarker",UDim2.new(.5,-15,.5,-15),UDim2.fromOffset(30,30),24)
local status=label("Feedback",UDim2.new(.5,-250,1,-126),UDim2.fromOffset(500,36),14)
status.TextWrapped=true
local reticle=Instance.new("Frame")
reticle.Name="Crosshair";reticle.BackgroundTransparency=1;reticle.Size=UDim2.fromOffset(0,0);reticle.Position=UDim2.fromScale(.5,.5);reticle.Parent=gui
local crossLines: {Frame}={}
for _,name in {"Left","Right","Top","Bottom","Dot"} do
    local line=Instance.new("Frame");line.Name=name;line.BorderSizePixel=0
    line.AnchorPoint=Vector2.new(.5,.5);line.BackgroundColor3=Color3.fromRGB(230,222,192)
    line.Size=if name=="Dot" then UDim2.fromOffset(2,2) elseif name=="Left" or name=="Right" then UDim2.fromOffset(6,2) else UDim2.fromOffset(2,6)
    line.Parent=reticle;table.insert(crossLines,line)
end
local vm=Instance.new("Model");vm.Name="ZO_LocalWeapon";vm.Parent=workspace.CurrentCamera
local held,aimHeld=false,false
local aimAlpha=0
local nextAction,hitUntil,swingUntil=0,0,0
local hitHead=false
local viewKick,cameraKick,appliedCameraKick,bloom=0,0,0,0
local kickCamera: Camera?=nil
local fovCamera: Camera?=nil
local normalFov=70
local controlsFov=false
local originalCameraMode=player.CameraMode
local notice,noticeUntil="",0
local practiceOrigin: Vector3?=nil
local practiceTarget: Vector3?=nil
local practiceDeadline=0
local assets: Instance?=nil
local assetsBound=false
local assetWaitExpired=false
local templateStates: {[Instance]: string}={}
local currentPresentation: any=nil
local currentTemplate: Tool?=nil
local presentationId=""
local presentationCharacter: Model?=nil
local presentationDirty=true
local presentationStatus="Loading"
local zombieArms: any=nil
local zombieCharacter: Model?=nil
local armsStatus="Loading"
local function role(): string? return player.Team and player.Team.Name end
local function phase(): string?
    return Rules.phase(RS:GetAttribute("ZO_RoundState"),RunService:IsStudio(),workspace:GetAttribute("ZO_BarricadePractice")==true,#Players:GetPlayers())
end
local function humanoid(): Humanoid? return player.Character and player.Character:FindFirstChildOfClass("Humanoid") end
local function weapon() return Config.Weapons[player:GetAttribute("ZO_WeaponId")] or Config.Weapons.Rifle end
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
local function canAim(): boolean
    return canShoot() and not UIS:GetFocusedTextBox() and player:GetAttribute("ZO_Reloading")~=true
        and workspace:GetServerTimeNow()>=(player:GetAttribute("ZO_EquipReadyAt") or 0)
end
local function templateFor(id: string): Tool?
    local folder=assets and assets:FindFirstChild("Weapons")
    local template=folder and folder:FindFirstChild(id)
    return if template and template:IsA("Tool") then template else nil
end
local function updateAssetsStatus()
    if disposed then return end
    local ready,loading,failed=0,0,0
    for _,id in Config.WeaponOrder do
        local template=templateFor(id)
        local state=template and templateStates[template]
        local sourceState=assets and assets:GetAttribute("Status_"..id)
        if state=="Ready" then ready+=1
        elseif state=="Loading" or sourceState=="Loading" or (not assets and not assetWaitExpired) then loading+=1
        else failed+=1 end
    end
    local state=if loading>0 then "Loading" elseif failed==0 and ready>0 then "Ready" elseif ready>0 then "Partial" else "Failed"
    if player:GetAttribute("ZO_WeaponAssetsStatus")~=state then player:SetAttribute("ZO_WeaponAssetsStatus",state) end
end
local function preload(template: Tool)
    if templateStates[template] then return end
    templateStates[template]="Loading"
    task.spawn(function()
        local complete=false
        task.delay(20,function()
            if not complete and not disposed then templateStates[template]="Failed";updateAssetsStatus() end
        end)
        local failed=false
        local ok,problem=pcall(function()
            ContentProvider:PreloadAsync({template},function(_,fetchStatus)
                if fetchStatus~=Enum.AssetFetchStatus.Success then failed=true end
            end)
        end)
        complete=true
        if disposed then return end
        templateStates[template]=if ok and not failed then "Ready" else "Failed"
        updateAssetsStatus()
        if not ok or failed then warn("[K17] Assets de "..template.Name.." indisponíveis neste cliente: "..tostring(problem or "download/permissão")) end
    end)
end
local function scanAssets()
    for _,id in Config.WeaponOrder do
        local template=templateFor(id)
        if template then preload(template) end
    end
    presentationDirty=true;updateAssetsStatus()
end
local function bindAssets(candidate: Instance?)
    if assetsBound and candidate==assets then return end
    disconnectAll(assetConnections);assets=candidate;assetsBound=true
    if assets then
        table.insert(assetConnections,assets.DescendantAdded:Connect(scanAssets))
        table.insert(assetConnections,assets.DescendantRemoving:Connect(function() task.defer(scanAssets) end))
        table.insert(assetConnections,assets.AttributeChanged:Connect(updateAssetsStatus))
    end
    scanAssets()
end
connect(RS.ChildAdded,function(item: Instance) if item.Name=="ZO_WeaponAssets" then bindAssets(item) end end)
connect(RS.ChildRemoved,function(item: Instance) if item==assets then bindAssets(nil) end end)
bindAssets(RS:FindFirstChild("ZO_WeaponAssets"))
task.delay(20,function()
    if disposed then return end
    assetWaitExpired=true;presentationDirty=true;updateAssetsStatus()
end)
local function restoreFov()
    if fovCamera and controlsFov then fovCamera.FieldOfView=normalFov end
    controlsFov=false
end
local function clearCameraKick()
    if kickCamera and kickCamera==workspace.CurrentCamera and appliedCameraKick~=0 then
        kickCamera.CFrame*=CFrame.Angles(math.rad(-appliedCameraKick),0,0)
    end
    cameraKick=0;appliedCameraKick=0;viewKick=0;bloom=0;kickCamera=nil
end
local function stop()
    held=false;aimHeld=false;aimAlpha=0;nextAction=0;swingUntil=0
    restoreFov();clearCameraKick()
    if currentPresentation then currentPresentation:stop() end
end
local function destroyPresentation()
    if currentPresentation then currentPresentation:destroy();currentPresentation=nil end
    currentTemplate=nil;presentationId="";presentationCharacter=nil
end
local function ensurePresentation(id: string)
    local template=templateFor(id)
    local character=player.Character
    if not presentationDirty and presentationId==id and currentTemplate==template and presentationCharacter==character then return end
    presentationDirty=false
    destroyPresentation();presentationId=id;currentTemplate=template;presentationCharacter=character
    if not template then
        presentationStatus=if (assets and assets:GetAttribute("Status_"..id)~="Loading") or (not assets and assetWaitExpired) then "MissingAsset" else "Loading"
    else
        local ok,result,reason=pcall(Presentation.new,template,vm,id,character)
        if ok then currentPresentation=result;presentationStatus=if result then (reason or "Ready") else (reason or "InvalidAsset")
        else presentationStatus="InvalidAsset";warn("[K17] Apresentação de "..id..": "..tostring(result)) end
    end
    player:SetAttribute("ZO_WeaponPresentationStatus",presentationStatus)
end
local function ensureZombieArms()
    if zombieCharacter==player.Character then return end
    if zombieArms then Presentation.destroyArms(zombieArms);zombieArms=nil end
    zombieCharacter=player.Character
    if zombieCharacter then zombieArms,armsStatus=Presentation.newArms(zombieCharacter,vm) end
end
local function action()
    local camera=workspace.CurrentCamera
    if not camera or UIS:GetFocusedTextBox() or menuOpen() or os.clock()<nextAction then return end
    local equipped=weapon()
    if canShoot() and player:GetAttribute("ZO_Reloading")~=true and (player:GetAttribute("ZO_Ammo") or 0)>0
        and workspace:GetServerTimeNow()>=(player:GetAttribute("ZO_EquipReadyAt") or 0) then
        if not templateFor(equipped.Id) then
            notice="Modelo da arma indisponível · veja o carregamento do arsenal";noticeUntil=os.clock()+2
            return
        end
        nextAction=os.clock()+equipped.FireInterval+.005
        local aiming=aimHeld and canAim()
        rifle:FireServer("Fire",camera.CFrame.LookVector,aiming)
        ensurePresentation(equipped.Id)
        if currentPresentation then
            currentPresentation:update(camera.CFrame,CFrame.new(0,0,viewKick),true,aimAlpha)
            currentPresentation:fire()
        end
        local settings=PresentationConfig.get(equipped.Id)
        local scale=equipped.Recoil*(if aiming then .65 else 1)
        viewKick=math.min(viewKick+settings.ViewKick*scale,.45)
        cameraKick=math.min(cameraKick+settings.RecoilPitch*scale,5)
        bloom=math.min(bloom+4*scale,22)
    elseif canMelee() then
        nextAction=os.clock()+Config.Melee.Cooldown+.02;swingUntil=os.clock()+.24
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
    if UIS:GetFocusedTextBox() or (not canShoot() and not canMelee()) then return Enum.ContextActionResult.Pass end
    if state==Enum.UserInputState.Begin then
        if input.UserInputType==Enum.UserInputType.MouseButton1 and overButton() then return Enum.ContextActionResult.Pass end
        held=true;action()
    end
    return Enum.ContextActionResult.Sink
end
local function aim(_,state: Enum.UserInputState,input: InputObject): Enum.ContextActionResult
    if state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel then aimHeld=false;return Enum.ContextActionResult.Pass end
    if not canAim() then return Enum.ContextActionResult.Pass end
    if state==Enum.UserInputState.Begin then
        if input.UserInputType==Enum.UserInputType.MouseButton2 and overButton() then return Enum.ContextActionResult.Pass end
        aimHeld=true
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
for _,name in {"ZO_Trigger","ZO_Aim","ZO_Reload","ZO_Equip"} do CAS:UnbindAction(name) end
CAS:BindActionAtPriority("ZO_Trigger",trigger,true,2200,Enum.UserInputType.MouseButton1,Enum.KeyCode.ButtonR2)
CAS:BindActionAtPriority("ZO_Aim",aim,true,2200,Enum.UserInputType.MouseButton2,Enum.KeyCode.ButtonL2)
CAS:BindActionAtPriority("ZO_Reload",reload,true,2200,Enum.KeyCode.R,Enum.KeyCode.ButtonX)
CAS:BindActionAtPriority("ZO_Equip",equip,false,2200,Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Q,Enum.KeyCode.ButtonY)
CAS:SetTitle("ZO_Trigger","Atacar");CAS:SetPosition("ZO_Trigger",UDim2.new(1,-150,1,-170))
CAS:SetTitle("ZO_Reload","Recarregar");CAS:SetPosition("ZO_Reload",UDim2.new(1,-235,1,-170))
CAS:SetTitle("ZO_Aim","Mira");CAS:SetPosition("ZO_Aim",UDim2.new(1,-320,1,-170))
for _,name in {"ZO_TacticalMapOpen","ZO_ShopOpen","ZO_BarricadeSelection"} do
    connect(player:GetAttributeChangedSignal(name),function() if menuOpen() or not canShoot() then stop() end end)
end
connect(player:GetAttributeChangedSignal("ZO_WeaponId"),function() stop();presentationDirty=true end)
connect(player:GetAttributeChangedSignal("ZO_Reloading"),function() if player:GetAttribute("ZO_Reloading")==true then stop() end end)
connect(player:GetAttributeChangedSignal("ZO_EquipReadyAt"),function() if not canAim() then stop() end end)
connect(UIS.WindowFocusReleased,stop);connect(UIS.TextBoxFocused,stop);connect(GuiService.MenuOpened,stop)
connect(player.CharacterRemoving,function()
    stop();destroyPresentation();presentationDirty=true;zombieCharacter=nil
    if zombieArms then Presentation.destroyArms(zombieArms);zombieArms=nil end
end)
connect(player:GetPropertyChangedSignal("Team"),stop)
connect(RS:GetAttributeChangedSignal("ZO_RoundState"),function() if phase()~="Active" and phase()~="Preparation" then stop() end end)
local function observeWorldCharacter(owner: Player,character: Model)
    local function observe(item: Instance)
        if owner~=player and item:IsA("Tool") and (item.Name=="ZO_EquippedWeapon" or item.Name=="ZO_EquippedRifle") then Presentation.observeWorld(item) end
    end
    for _,item in character:GetChildren() do observe(item) end
    local added=character.ChildAdded:Connect(observe)
    table.insert(connections,added)
    character.Destroying:Once(function() added:Disconnect() end)
end
local function observePlayer(owner: Player)
    if owner.Character then observeWorldCharacter(owner,owner.Character) end
    connect(owner.CharacterAdded,function(character) observeWorldCharacter(owner,character) end)
end
for _,owner in Players:GetPlayers() do observePlayer(owner) end
connect(Players.PlayerAdded,observePlayer)
local function bindCharacter(character: Model)
    disconnectAll(characterConnections);presentationDirty=true;zombieCharacter=nil
    local function bindHumanoid(hum: Humanoid)
        table.insert(characterConnections,hum.Died:Connect(stop))
    end
    local hum=character:FindFirstChildOfClass("Humanoid")
    if hum then bindHumanoid(hum) end
    table.insert(characterConnections,character.DescendantAdded:Connect(function(item)
        if item:IsA("Humanoid") then bindHumanoid(item) end
        if item.Name=="RightHand" or item.Name=="LeftHand" or item.Name=="HumanoidRootPart" then presentationDirty=true;zombieCharacter=nil end
    end))
end
if player.Character then bindCharacter(player.Character) end
connect(player.CharacterAdded,bindCharacter)
connect(player.CharacterAppearanceLoaded,function() presentationDirty=true;zombieCharacter=nil end)
connect(rifle.OnClientEvent,function(kind: string,_damage: any,hitgroup: any)
    if kind=="Hit" then hitUntil=os.clock()+.14;hitHead=hitgroup=="Head"
    elseif kind=="PropHit" then notice="Barricada atingida";noticeUntil=os.clock()+.6 end
end)
connect(melee.OnClientEvent,function(kind: string,value: any)
    if kind=="Infected" then stop();notice="INFECÇÃO";hitUntil=os.clock()+.2;hitHead=false
    elseif kind=="Barricade" then notice=if value<=0 then "Objeto destruído" else ("Resistência: %d"):format(value);hitUntil=os.clock()+.12;hitHead=false
    else notice="" end
    noticeUntil=os.clock()+1
end)
connect(effects.OnClientEvent,function(kind: string,origin: any,destination: any,shooter: any,weaponId: any,hitNormal: any,firstRay: any)
    if kind=="PracticeAim" and RunService:IsStudio() and typeof(origin)=="Vector3" and typeof(destination)=="Vector3" then
        practiceOrigin=origin;practiceTarget=destination;practiceDeadline=os.clock()+3;return
    end
    if kind~="Shot" or typeof(origin)~="Vector3" or typeof(destination)~="Vector3" then return end
    local shotWeapon=Config.Weapons[weaponId] or Config.Weapons.Rifle
    -- Predicted local sound/muzzle is emitted once; observers use world attachments.
    if firstRay~=false and shooter~=player.UserId and typeof(shooter)=="number" then
        local other=Players:GetPlayerByUserId(shooter)
        local character=other and other.Character
        local tool=character and character:FindFirstChild("ZO_EquippedWeapon")
        if tool and tool:IsA("Tool") and (tool:GetAttribute("ZO_WeaponId") or "Rifle")==shotWeapon.Id then Presentation.playWorldShot(tool)
        else
            local template=templateFor(shotWeapon.Id)
            if template then Presentation.playDistantShot(template,origin,shotWeapon.Id) end
        end
    end
    if typeof(hitNormal)=="Vector3" and hitNormal.Magnitude>.001 then Presentation.impact(destination,hitNormal.Unit) end
    local distance=(destination-origin).Magnitude
    if distance<.1 then return end
    -- Query-free trace uses only the server result; it cannot register hits.
    local color=shotWeapon.Color
    local trace=Instance.new("Part");trace.Name="ZO_ShotTrace"
    trace.Size=Vector3.new(.035,.035,distance);trace.CFrame=CFrame.lookAt((origin+destination)/2,destination)
    trace.Anchored=true;trace.CanCollide=false;trace.CanQuery=false;trace.CanTouch=false;trace.CastShadow=false
    trace.Material=Enum.Material.Neon;trace.Color=Color3.fromRGB(color[1],color[2],color[3]);trace.Transparency=.4
    trace.Parent=workspace;Debris:AddItem(trace,.045)
end)
local renderName="ZO_WeaponPresentation"
RunService:UnbindFromRenderStep(renderName)
RunService:BindToRenderStep(renderName,Enum.RenderPriority.Camera.Value+1,function(dt: number)
    if disposed then return end
    if held and (canMelee() or weapon().Automatic) then action() end
    local camera=workspace.CurrentCamera
    if not camera then return end
    if fovCamera~=camera then
        restoreFov();clearCameraKick();fovCamera=camera;normalFov=camera.FieldOfView
    end
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
    if not canAim() then
        if aimHeld or aimAlpha>0 then aimHeld=false;aimAlpha=0;restoreFov() end
    end
    local equipped=weapon()
    if gun then ensurePresentation(equipped.Id) end
    local targetAim=if aimHeld and canAim() then 1 else 0
    aimAlpha+=(targetAim-aimAlpha)*(1-math.exp(-dt*14))
    if aimAlpha>.001 or targetAim==1 then
        if not controlsFov then normalFov=camera.FieldOfView;controlsFov=true end
        camera.FieldOfView=normalFov+(PresentationConfig.get(equipped.Id).AimFov-normalFov)*aimAlpha
    elseif controlsFov then restoreFov() else normalFov=camera.FieldOfView end
    -- Apply the change in recoil, so each impulse rises and recovers gradually.
    local kickDelta=cameraKick-appliedCameraKick
    if math.abs(kickDelta)>.0001 then camera.CFrame*=CFrame.Angles(math.rad(kickDelta),0,0) end
    appliedCameraKick=cameraKick;kickCamera=camera
    cameraKick*=math.exp(-dt*9);viewKick*=math.exp(-dt*14);bloom*=math.exp(-dt*8)
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
    if currentPresentation then
        currentPresentation:update(camera.CFrame,reloadPose*CFrame.new(0,0,viewKick),gun and presentationId==equipped.Id,aimAlpha)
        currentPresentation:setReloading(gun and reloading,remaining)
    end
    if zombie then ensureZombieArms() end
    if zombieArms then Presentation.updateArms(zombieArms,camera.CFrame,zombie,math.max(0,(swingUntil-os.clock())/.24)) end
    local visibleStatus=if gun then presentationStatus elseif zombie then armsStatus else "Inactive"
    if player:GetAttribute("ZO_WeaponPresentationStatus")~=visibleStatus then player:SetAttribute("ZO_WeaponPresentationStatus",visibleStatus) end
    -- Hide only this observer's world Tool while using its first-person copy.
    local character=player.Character
    if character then
        for _,tool in character:GetChildren() do
            if tool:IsA("Tool") and (tool.Name=="ZO_EquippedWeapon" or tool.Name=="ZO_EquippedRifle") then
                for _,part in tool:GetDescendants() do
                    if part:IsA("BasePart") then part.LocalTransparencyModifier=if firstPerson then 1 else 0 end
                end
            end
        end
    end
    ammo.Visible=gun;health.Visible=active;cross.Visible=active;reticle.Visible=active
    local clip=player:GetAttribute("ZO_Ammo") or 0
    ammo.Text=if reloading then ("RECARREGANDO  %.1fs"):format(remaining) elseif equipping then "EQUIPANDO..."
        else ("%s  %02d/%d  |  %03d"):format(string.upper(equipped.Label),clip,equipped.Magazine,player:GetAttribute("ZO_Reserve") or 0)
    health.Text=("%s  %d"):format(if zombie then "ZUMBI" else "VIDA",math.ceil(if hum then hum.Health else 0))
    local hit=os.clock()<hitUntil
    cross.Text=if hit then "×" else ""
    cross.TextColor3=if hitHead then Color3.fromRGB(255,109,91) else Color3.fromRGB(230,222,192)
    local moving=hum~=nil and hum.MoveDirection.Magnitude>.1
    local spread=Rules.shotSpread(equipped,moving,targetAim==1)
    local pixels=math.tan(math.rad(spread))*camera.ViewportSize.Y/(2*math.tan(math.rad(camera.FieldOfView/2)))
    local gap=if zombie then 7 else math.clamp(4+pixels+bloom,4,48)
    for i,line in crossLines do
        line.Position=if i==1 then UDim2.fromOffset(-gap,0) elseif i==2 then UDim2.fromOffset(gap,0)
            elseif i==3 then UDim2.fromOffset(0,-gap) elseif i==4 then UDim2.fromOffset(0,gap) else UDim2.fromOffset(0,0)
        line.BackgroundTransparency=if i==5 then (if hit then 1 else .1) else aimAlpha*.8
        line.BackgroundColor3=if zombie then Color3.fromRGB(211,128,101) else Color3.fromRGB(230,222,192)
    end
    local assetFailure=gun and currentTemplate and templateStates[currentTemplate]=="Failed"
    status.Text=if os.clock()<noticeUntil then notice
        elseif gun and presentationStatus=="Loading" then "Carregando modelo da arma..."
        elseif gun and not currentPresentation then "Modelo da arma indisponível · veja o Output"
        elseif assetFailure then "Assets da arma indisponíveis · veja o Output"
        elseif (gun and presentationStatus~="Ready") or (zombie and not zombieArms) then "Braços em primeira pessoa requerem personagem R15"
        elseif gun and clip==0 then "Recarregar · 1 / 2: trocar arma"
        elseif zombie then "Segure atacar para golpear e infectar" else ""
    status.Visible=active
    local triggerButton=CAS:GetButton("ZO_Trigger");if triggerButton then triggerButton.Visible=active end
    local reloadButton=CAS:GetButton("ZO_Reload");if reloadButton then reloadButton.Visible=gun end
    local aimButton=CAS:GetButton("ZO_Aim");if aimButton then aimButton.Visible=gun and not reloading and not equipping end
end)
connect(script.Destroying,function()
    if disposed then return end
    disposed=true;stop();RunService:UnbindFromRenderStep(renderName)
    for _,name in {"ZO_Trigger","ZO_Aim","ZO_Reload","ZO_Equip"} do CAS:UnbindAction(name) end
    disconnectAll(connections);disconnectAll(assetConnections);disconnectAll(characterConnections)
    destroyPresentation();if zombieArms then Presentation.destroyArms(zombieArms) end
    player.CameraMode=originalCameraMode;vm:Destroy();gui:Destroy()
end)
