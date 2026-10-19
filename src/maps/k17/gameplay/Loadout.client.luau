--!strict
-- The shop only requests actions. Prices, ownership, credits and ammunition are server-owned.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local CAS=game:GetService("ContextActionService")
local GuiService=game:GetService("GuiService")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local Config=require(RS:WaitForChild("K17Gameplay").Config)
local Rules=require(RS.K17Gameplay.Rules)
local remote=RS:WaitForChild("ZO_LoadoutAction") :: RemoteEvent
local playerGui=player:WaitForChild("PlayerGui")
local colors={base=Color3.fromRGB(16,23,27),raised=Color3.fromRGB(29,39,44),line=Color3.fromRGB(63,81,84),text=Color3.fromRGB(232,240,235),muted=Color3.fromRGB(164,183,182),accent=Color3.fromRGB(150,221,182),gold=Color3.fromRGB(232,195,122),red=Color3.fromRGB(240,146,127)}
local gui=Instance.new("ScreenGui")
gui.Name="ZO_Loadout";gui.ResetOnSpawn=false;gui.DisplayOrder=50;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.Parent=playerGui
local function round(parent: GuiObject,radius: number)
    local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,radius);corner.Parent=parent
end
local function stroke(parent: GuiObject,color: Color3): UIStroke
    local item=Instance.new("UIStroke");item.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;item.Thickness=1;item.Color=color;item.Parent=parent;return item
end
local function text(parent: Instance,name: string,value: string,size: number): TextLabel
    local label=Instance.new("TextLabel");label.Name=name;label.BackgroundTransparency=1;label.Font=Enum.Font.Gotham
    label.Text=value;label.TextSize=size;label.TextColor3=colors.text;label.TextXAlignment=Enum.TextXAlignment.Left
    label.TextYAlignment=Enum.TextYAlignment.Top;label.TextWrapped=true;label.Parent=parent;return label
end
local function button(parent: Instance,name: string,value: string,size: number): TextButton
    local item=Instance.new("TextButton");item.Name=name;item.Text=value;item.TextSize=size;item.Font=Enum.Font.GothamMedium
    item.TextColor3=colors.text;item.BackgroundColor3=colors.raised;item.BorderSizePixel=0;item.AutoButtonColor=true
    item.Parent=parent;round(item,7);return item
end
local toggle=button(gui,"OpenShop","B  ARSENAL",13)
toggle.AnchorPoint=Vector2.new(0,1);toggle.Position=UDim2.new(0,20,1,-24);toggle.Size=UDim2.fromOffset(128,42)
stroke(toggle,colors.accent)
local touchPrimary=button(gui,"EquipPrimary","1  PRIMÁRIA",11)
touchPrimary.AnchorPoint=Vector2.new(0,1);touchPrimary.Position=UDim2.new(0,20,1,-76);touchPrimary.Size=UDim2.fromOffset(122,36)
local touchSecondary=button(gui,"EquipSecondary","2  PISTOLA",11)
touchSecondary.AnchorPoint=Vector2.new(0,1);touchSecondary.Position=UDim2.new(0,150,1,-76);touchSecondary.Size=UDim2.fromOffset(116,36)
local shade=button(gui,"Backdrop","",1)
shade.Size=UDim2.fromScale(1,1);shade.BackgroundColor3=Color3.new(0,0,0);shade.BackgroundTransparency=.2
shade.AutoButtonColor=false;shade.Modal=true;shade.Visible=false;shade.Selectable=false
local panel=Instance.new("Frame");panel.Name="Arsenal";panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.5)
panel.Size=UDim2.fromScale(.95,.94);panel.BackgroundColor3=colors.base;panel.BorderSizePixel=0;panel.Active=true;panel.Visible=false;panel.Parent=gui
round(panel,12);stroke(panel,colors.line)
local limit=Instance.new("UISizeConstraint");limit.MaxSize=Vector2.new(960,680);limit.Parent=panel
local title=text(panel,"Title","K-17  /  ARSENAL",20);title.Font=Enum.Font.GothamBold;title.Position=UDim2.fromOffset(18,14);title.Size=UDim2.new(1,-82,0,28)
local close=button(panel,"Close","×",25);close.AnchorPoint=Vector2.new(1,0);close.Position=UDim2.new(1,-12,0,10);close.Size=UDim2.fromOffset(42,36)
local credits=text(panel,"Credits","",15);credits.Font=Enum.Font.GothamBold;credits.TextColor3=colors.gold;credits.Position=UDim2.fromOffset(18,47);credits.Size=UDim2.new(1,-36,0,22)
local inventory=text(panel,"Inventory","",12);inventory.Position=UDim2.fromOffset(18,73);inventory.Size=UDim2.new(1,-36,0,34);inventory.TextColor3=colors.muted
local availability=text(panel,"Availability","",12);availability.Position=UDim2.fromOffset(18,112);availability.Size=UDim2.new(1,-36,0,32)
local body=Instance.new("Frame");body.Name="Catalog";body.BackgroundTransparency=1;body.Position=UDim2.fromOffset(18,152);body.Size=UDim2.new(1,-36,1,-274);body.Parent=panel
local list=Instance.new("ScrollingFrame");list.Name="Weapons";list.BackgroundTransparency=1;list.BorderSizePixel=0
list.Size=UDim2.new(.42,-6,1,0);list.ScrollBarThickness=4;list.ScrollBarImageColor3=colors.accent;list.CanvasSize=UDim2.new();list.AutomaticCanvasSize=Enum.AutomaticSize.Y;list.Parent=body
local listLayout=Instance.new("UIListLayout");listLayout.Padding=UDim.new(0,8);listLayout.SortOrder=Enum.SortOrder.LayoutOrder;listLayout.Parent=list
local listPadding=Instance.new("UIPadding");listPadding.PaddingTop=UDim.new(0,2);listPadding.PaddingLeft=UDim.new(0,2);listPadding.PaddingRight=UDim.new(0,7);listPadding.PaddingBottom=UDim.new(0,3);listPadding.Parent=list
local detail=Instance.new("ScrollingFrame");detail.Name="WeaponDetail";detail.BackgroundColor3=colors.raised;detail.BorderSizePixel=0
detail.Position=UDim2.new(.42,8,0,0);detail.Size=UDim2.new(.58,-8,1,0);detail.ScrollBarThickness=4;detail.ScrollBarImageColor3=colors.accent
detail.CanvasSize=UDim2.new();detail.AutomaticCanvasSize=Enum.AutomaticSize.Y;detail.Parent=body;round(detail,8)
local detailPadding=Instance.new("UIPadding");detailPadding.PaddingLeft=UDim.new(0,12);detailPadding.PaddingRight=UDim.new(0,12);detailPadding.PaddingTop=UDim.new(0,12);detailPadding.PaddingBottom=UDim.new(0,12);detailPadding.Parent=detail
local detailLayout=Instance.new("UIListLayout");detailLayout.Padding=UDim.new(0,12);detailLayout.SortOrder=Enum.SortOrder.LayoutOrder;detailLayout.Parent=detail
local function detailText(name: string,size: number,order: number): TextLabel
    local item=text(detail,name,"",size);item.Size=UDim2.new(1,-6,0,0);item.AutomaticSize=Enum.AutomaticSize.Y;item.LayoutOrder=order;return item
end
local selectedName=detailText("WeaponName",20,1);selectedName.Font=Enum.Font.GothamBold
local selectedRole=detailText("WeaponRole",12,2);selectedRole.TextColor3=colors.gold
local description=detailText("Description",13,3)
local stats=detailText("Stats",13,4);stats.TextColor3=colors.muted
local selectedStatus=detailText("Ownership",12,5);selectedStatus.TextColor3=colors.accent
local footer=Instance.new("Frame");footer.Name="Actions";footer.BackgroundTransparency=1;footer.Position=UDim2.new(0,18,1,-108);footer.Size=UDim2.new(1,-36,0,94);footer.Parent=panel
local buy=button(footer,"Buy","COMPRAR",13);buy.Size=UDim2.new(1,0,0,38)
local equip=button(footer,"Equip","EQUIPAR",12);equip.Position=UDim2.fromOffset(0,46);equip.Size=UDim2.new(.5,-4,0,38)
local ammo=button(footer,"Ammo","MUNIÇÃO",12);ammo.Position=UDim2.new(.5,4,0,46);ammo.Size=UDim2.new(.5,-4,0,38)
local cards: {[string]: {Button: TextButton,Price: TextLabel,Stroke: UIStroke}}={}
local selected="Rifle"
local open=false
local pending: string?=nil
local pendingSerial=0
local message=""
local messageExpires=0
local messageOK=true
local previousMouse=Enum.MouseBehavior.Default
local previousIcon=true
local previousSelection: GuiObject?=nil
local function role(): string? return player.Team and player.Team.Name end
local function alive(): boolean
    local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    return hum~=nil and hum.Health>0
end
local function phase(): string?
    return Rules.phase(RS:GetAttribute("ZO_RoundState"),RunService:IsStudio(),workspace:GetAttribute("ZO_BarricadePractice")==true,#Players:GetPlayers())
end
local function soloPractice(): boolean
    return RunService:IsStudio() and #Players:GetPlayers()==1 and workspace:GetAttribute("ZO_BarricadePractice")==true and RS:GetAttribute("ZO_RoundState")=="Waiting"
end
local function canBuy(): boolean return role()=="Humans" and alive() and (phase()=="Preparation" or soloPractice()) end
local function canEquip(): boolean return role()=="Humans" and alive() and (phase()=="Preparation" or phase()=="Active") end
local function owned(id: string): boolean
    return id==player:GetAttribute("ZO_PrimaryWeapon") or id==player:GetAttribute("ZO_SecondaryWeapon")
end
local function weaponName(id: any): string
    local item=Config.Weapons[id];return if item then item.Label else "—"
end
local function setEnabled(item: TextButton,enabled: boolean)
    item.Active=enabled;item.Selectable=enabled;item.AutoButtonColor=enabled
    item.BackgroundColor3=if enabled then Color3.fromRGB(55,88,73) else colors.raised
    item.TextColor3=if enabled then colors.text else Color3.fromRGB(122,139,141)
end
local refresh: ()->()
local setOpen: (boolean)->()
for index,id in Config.WeaponOrder do
    local item=Config.Weapons[id]
    local card=button(list,id,"",12);card.Size=UDim2.new(1,-3,0,72);card.LayoutOrder=index
    local border=stroke(card,colors.line)
    local accent=Instance.new("Frame");accent.Name="WeaponColor";accent.Size=UDim2.new(0,4,1,-18);accent.Position=UDim2.fromOffset(7,9)
    accent.BackgroundColor3=Color3.fromRGB(item.Color[1],item.Color[2],item.Color[3]);accent.BorderSizePixel=0;accent.Parent=card
    local name=text(card,"Label",item.Label,13);name.Font=Enum.Font.GothamMedium;name.Position=UDim2.fromOffset(18,9);name.Size=UDim2.new(1,-28,0,31)
    local price=text(card,"Price","",11);price.Position=UDim2.fromOffset(18,45);price.Size=UDim2.new(1,-24,0,21);price.TextColor3=colors.muted
    cards[id]={Button=card,Price=price,Stroke=border}
    card.Activated:Connect(function() selected=id;message="";refresh() end)
end
local function availabilityText(): (string,Color3)
    if pending then return "Aguardando confirmação do servidor…",colors.gold end
    if message~="" and os.clock()<messageExpires then return message,if messageOK then colors.accent else colors.red end
    if role()~="Humans" then return "Somente humanos vivos podem comprar ou trocar armas.",colors.muted end
    if not alive() then return "Você está fora de combate. Aguarde o próximo nascimento.",colors.muted end
    if canBuy() then
        if soloPractice() then
            return "TREINO SOLO · compras habilitadas, com o mesmo custo da rodada.",colors.accent
        end
        return "PREPARAÇÃO · compre agora. Munição repõe as reservas das duas armas.",colors.accent
    end
    if phase()=="Active" then return "COMPRAS ENCERRADAS · troque entre suas armas com 1 / 2 ou Q.",colors.gold end
    return "O arsenal abre para compras durante a preparação da rodada.",colors.muted
end
refresh=function()
    local balance=player:GetAttribute("ZO_Credits") or 0
    local primary,secondary=player:GetAttribute("ZO_PrimaryWeapon"),player:GetAttribute("ZO_SecondaryWeapon")
    credits.Text=("CRÉDITOS  $%d"):format(balance)
    inventory.Text=("Primária: %s   |   Secundária: %s\nEm mãos: %s"):format(weaponName(primary),weaponName(secondary),weaponName(player:GetAttribute("ZO_WeaponId")))
    local stateText,stateColor=availabilityText();availability.Text=stateText;availability.TextColor3=stateColor
    local item=Config.Weapons[selected]
    local isOwned=owned(selected)
    for id,card in cards do
        local entry=Config.Weapons[id]
        card.Stroke.Color=if id==selected then colors.accent else colors.line
        card.Stroke.Thickness=if id==selected then 2 else 1
        card.Button.BackgroundColor3=if id==selected then Color3.fromRGB(41,60,58) else colors.raised
        card.Price.Text=if id==player:GetAttribute("ZO_WeaponId") then "EM MÃOS" elseif owned(id) then "NO SEU EQUIPAMENTO" else ("$%d"):format(entry.Price)
    end
    selectedName.Text=item.Label
    local roles={Rifle="Carabina equilibrada",SMG="Defesa móvel a curta distância",Shotgun="Contenção de entradas próximas",LMG="Fogo sustentado de defesa",Pistol="Secundária de emergência"}
    selectedRole.Text=roles[selected]
    description.Text=item.Description
    local damage=if item.Pellets>1 then ("%d × %d projéteis"):format(item.Damage,item.Pellets) else tostring(item.Damage)
    stats.Text=("Dano-base: %s\nCadência: %d disparos/min\nCarregador: %d  |  Reserva: %d\nRecarga: %.1fs\nModo: %s\nAlcance: %d"):format(damage,math.floor(60/item.FireInterval+.5),item.Magazine,item.Reserve,item.ReloadSeconds,if item.Automatic then "automático" else "semiautomático",item.Range)
    selectedStatus.Text=if selected==player:GetAttribute("ZO_WeaponId") then "EQUIPADA · munição atual: "..tostring(player:GetAttribute("ZO_Ammo") or 0).." / "..tostring(player:GetAttribute("ZO_Reserve") or 0)
        elseif isOwned then "NO SEU EQUIPAMENTO · trocar preserva a munição"
        elseif item.Slot=="Primary" then "A compra substitui sua arma primária. A pistola continua com você."
        else "A pistola é a secundária inicial de todo humano."
    buy.Text=if isOwned then "ARMA JÁ ADQUIRIDA" elseif balance<item.Price then ("COMPRAR $%d · faltam $%d"):format(item.Price,item.Price-balance) else ("COMPRAR  $%d"):format(item.Price)
    equip.Text=if selected==player:GetAttribute("ZO_WeaponId") then "EM MÃOS" else "EQUIPAR"
    ammo.Text=("MUNIÇÃO  $%d"):format(Config.Economy.AmmoPrice)
    setEnabled(buy,pending==nil and canBuy() and not isOwned and item.Slot=="Primary" and balance>=item.Price)
    setEnabled(equip,pending==nil and canEquip() and isOwned and selected~=player:GetAttribute("ZO_WeaponId"))
    setEnabled(ammo,pending==nil and canBuy() and balance>=Config.Economy.AmmoPrice)
    local human=role()=="Humans" and alive()
    touchPrimary.Visible=UIS.TouchEnabled and human and not open and player:GetAttribute("ZO_TacticalMapOpen")~=true
    touchSecondary.Visible=touchPrimary.Visible
    local shortNames={Rifle="CARABINA",SMG="SMG",Shotgun="ESCOPETA",LMG="METRALHADORA",Pistol="PISTOLA"}
    touchPrimary.Text="1  "..(shortNames[primary] or "PRIMÁRIA")
    touchSecondary.Text="2  "..string.upper(weaponName(secondary))
    touchPrimary.TextColor3=if primary==player:GetAttribute("ZO_WeaponId") then colors.accent else colors.text
    touchSecondary.TextColor3=if secondary==player:GetAttribute("ZO_WeaponId") then colors.accent else colors.text
    toggle.Text=if UIS.TouchEnabled then "ARSENAL" elseif UIS.GamepadEnabled and string.find(UIS:GetLastInputType().Name,"Gamepad") then "↑  ARSENAL" else "B  ARSENAL"
    toggle.Visible=not open and player:GetAttribute("ZO_TacticalMapOpen")~=true
end
setOpen=function(value: boolean)
    if open==value then return end
    open=value
    if value then
        previousMouse=UIS.MouseBehavior;previousIcon=UIS.MouseIconEnabled;previousSelection=GuiService.SelectedObject
        message="";selected=if Config.Weapons[player:GetAttribute("ZO_WeaponId")] then player:GetAttribute("ZO_WeaponId") else "Rifle"
    end
    shade.Visible=value;panel.Visible=value
    player:SetAttribute("ZO_ShopOpen",value)
    if value then
        UIS.MouseBehavior=Enum.MouseBehavior.Default;UIS.MouseIconEnabled=true
        if UIS.GamepadEnabled and string.find(UIS:GetLastInputType().Name,"Gamepad") then GuiService.SelectedObject=cards[selected].Button end
    else
        local selection=GuiService.SelectedObject
        if selection and selection:IsDescendantOf(panel) then
            GuiService.SelectedObject=if previousSelection and previousSelection.Parent then previousSelection else nil
        end
        if player:GetAttribute("ZO_TacticalMapOpen")~=true then UIS.MouseBehavior=previousMouse;UIS.MouseIconEnabled=previousIcon end
    end
    refresh()
end
local function request(action: string,id: string?)
    if pending then return end
    if action=="Buy" and (not canBuy() or owned(selected) or Config.Weapons[selected].Slot~="Primary") then return end
    if action=="Ammo" and not canBuy() then return end
    if action=="Equip" and (not canEquip() or not id or (id~="Primary" and id~="Secondary" and not owned(id))) then return end
    pending=action;pendingSerial+=1
    local serial=pendingSerial
    refresh();remote:FireServer(action,id)
    task.delay(4,function()
        if serial~=pendingSerial or not pending then return end
        pending=nil;message="Sem resposta do servidor. Tente novamente.";messageOK=false;messageExpires=os.clock()+5;refresh()
    end)
end
buy.Activated:Connect(function() request("Buy",selected) end)
equip.Activated:Connect(function() request("Equip",selected) end)
ammo.Activated:Connect(function() request("Ammo") end)
touchPrimary.Activated:Connect(function() if player:GetAttribute("ZO_TacticalMapOpen")~=true then request("Equip","Primary") end end)
touchSecondary.Activated:Connect(function() if player:GetAttribute("ZO_TacticalMapOpen")~=true then request("Equip","Secondary") end end)
toggle.Activated:Connect(function() setOpen(not open) end)
close.Activated:Connect(function() setOpen(false) end)
shade.Activated:Connect(function() setOpen(false) end)
remote.OnClientEvent:Connect(function(kind: any,ok: any,result: any)
    if kind~="Result" then return end
    pending=nil;pendingSerial+=1;messageOK=ok==true
    message=if type(result)=="string" then result else if messageOK then "Equipamento atualizado." else "Não foi possível concluir a ação."
    messageExpires=os.clock()+4;refresh()
end)
local function toggleAction(_,state: Enum.UserInputState): Enum.ContextActionResult
    if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
    if state==Enum.UserInputState.Begin then setOpen(not open) end
    return Enum.ContextActionResult.Sink
end
local function closeAction(_,state: Enum.UserInputState): Enum.ContextActionResult
    if not open then return Enum.ContextActionResult.Pass end
    if state==Enum.UserInputState.Begin then setOpen(false) end
    return Enum.ContextActionResult.Sink
end
CAS:BindActionAtPriority("ZO_OpenShop",toggleAction,false,2300,Enum.KeyCode.B,Enum.KeyCode.DPadUp)
CAS:BindActionAtPriority("ZO_CloseShop",closeAction,false,2500,Enum.KeyCode.Escape,Enum.KeyCode.ButtonB)
local function layout()
    local compact=panel.AbsoluteSize.Y<440
    local narrow=panel.AbsoluteSize.X<500
    title.TextSize=if narrow then 16 else 20
    credits.TextSize=if narrow then 13 else 15
    if compact then
        credits.Position=UDim2.fromOffset(18,42);inventory.Position=UDim2.fromOffset(18,64);inventory.Size=UDim2.new(1,-36,0,0);inventory.Visible=false
        availability.Position=UDim2.fromOffset(18,67);availability.Size=UDim2.new(1,-36,0,30)
        body.Position=UDim2.fromOffset(18,103);body.Size=UDim2.new(1,-36,1,-162)
        footer.Position=UDim2.new(0,18,1,-49);footer.Size=UDim2.new(1,-36,0,36)
        buy.Position=UDim2.new();buy.Size=UDim2.new(.43,-5,0,36)
        equip.Position=UDim2.new(.43,2,0,0);equip.Size=UDim2.new(.24,-5,0,36)
        ammo.Position=UDim2.new(.67,2,0,0);ammo.Size=UDim2.new(.33,-2,0,36)
        buy.TextSize=11;equip.TextSize=11;ammo.TextSize=11
    else
        credits.Position=UDim2.fromOffset(18,47);inventory.Position=UDim2.fromOffset(18,73);inventory.Size=UDim2.new(1,-36,0,34);inventory.Visible=true
        availability.Position=UDim2.fromOffset(18,112);availability.Size=UDim2.new(1,-36,0,32)
        body.Position=UDim2.fromOffset(18,152);body.Size=UDim2.new(1,-36,1,-274)
        footer.Position=UDim2.new(0,18,1,-108);footer.Size=UDim2.new(1,-36,0,94)
        buy.Position=UDim2.new();buy.Size=UDim2.new(1,0,0,38)
        equip.Position=UDim2.fromOffset(0,46);equip.Size=UDim2.new(.5,-4,0,38)
        ammo.Position=UDim2.new(.5,4,0,46);ammo.Size=UDim2.new(.5,-4,0,38)
        buy.TextSize=if narrow then 11 else 13;equip.TextSize=12;ammo.TextSize=12
    end
end
panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
for _,name in {"ZO_WeaponId","ZO_PrimaryWeapon","ZO_SecondaryWeapon","ZO_Credits","ZO_Ammo","ZO_Reserve","ZO_Reloading"} do player:GetAttributeChangedSignal(name):Connect(refresh) end
player:GetAttributeChangedSignal("ZO_TacticalMapOpen"):Connect(function()
    if player:GetAttribute("ZO_TacticalMapOpen")==true then setOpen(false) end
    refresh()
end)
player.CharacterRemoving:Connect(function() setOpen(false);refresh() end)
local healthConnection: RBXScriptConnection?=nil
local function characterAdded(character: Model)
    if healthConnection then healthConnection:Disconnect();healthConnection=nil end
    local hum=character:WaitForChild("Humanoid",10)
    if hum and hum:IsA("Humanoid") then
        healthConnection=hum.HealthChanged:Connect(function() if hum.Health<=0 then setOpen(false) end;refresh() end)
    end
    refresh()
end
player.CharacterAdded:Connect(characterAdded)
if player.Character then task.spawn(characterAdded,player.Character) end
player:GetPropertyChangedSignal("Team"):Connect(function() setOpen(false);refresh() end)
RS:GetAttributeChangedSignal("ZO_RoundState"):Connect(refresh)
workspace:GetAttributeChangedSignal("ZO_BarricadePractice"):Connect(refresh)
Players.PlayerAdded:Connect(refresh);Players.PlayerRemoving:Connect(function() task.defer(refresh) end)
UIS.LastInputTypeChanged:Connect(function()
    refresh()
    if open and UIS.GamepadEnabled and string.find(UIS:GetLastInputType().Name,"Gamepad") then GuiService.SelectedObject=cards[selected].Button end
end)
UIS.WindowFocusReleased:Connect(function() setOpen(false) end)
GuiService.MenuOpened:Connect(function() setOpen(false) end)
local elapsed=0
RunService:BindToRenderStep("ZO_ShopCursor",Enum.RenderPriority.Camera.Value+5,function(dt)
    if open then
        UIS.MouseBehavior=Enum.MouseBehavior.Default;UIS.MouseIconEnabled=true
        elapsed+=dt
        if elapsed>=.25 then elapsed=0;refresh() end
    end
end)
player:SetAttribute("ZO_ShopOpen",false)
layout();refresh()
