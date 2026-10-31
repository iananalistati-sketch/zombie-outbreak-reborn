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
local previousGui=playerGui:FindFirstChild("ZO_Loadout")
if previousGui then previousGui:Destroy() end
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
round(panel,10);stroke(panel,colors.line)
local limit=Instance.new("UISizeConstraint");limit.MaxSize=Vector2.new(1120,780);limit.Parent=panel
local topRule=Instance.new("Frame");topRule.Name="SectionAccent";topRule.BorderSizePixel=0;topRule.BackgroundColor3=colors.gold
topRule.Position=UDim2.fromOffset(0,0);topRule.Size=UDim2.new(1,0,0,3);topRule.Parent=panel
local title=text(panel,"Title","K-17  /  SUPRIMENTOS",20);title.Font=Enum.Font.GothamBold;title.Position=UDim2.fromOffset(20,16);title.Size=UDim2.new(1,-84,0,26)
local close=button(panel,"Close","×",25);close.AnchorPoint=Vector2.new(1,0);close.Position=UDim2.new(1,-14,0,12);close.Size=UDim2.fromOffset(40,36)
local credits=text(panel,"Credits","",16);credits.Font=Enum.Font.GothamBold;credits.TextColor3=colors.gold;credits.Position=UDim2.fromOffset(20,50);credits.Size=UDim2.new(.55,0,0,24)
local timer=text(panel,"BuyTime","",12);timer.TextColor3=colors.muted;timer.Position=UDim2.new(.55,0,0,52);timer.Size=UDim2.new(.45,-64,0,24)
local inventory=text(panel,"Inventory","",12);inventory.Position=UDim2.fromOffset(20,82);inventory.Size=UDim2.new(1,-40,0,34);inventory.TextColor3=colors.muted
local availability=text(panel,"Availability","",12);availability.Position=UDim2.fromOffset(20,122);availability.Size=UDim2.new(1,-40,0,30)
local body=Instance.new("Frame");body.Name="Catalog";body.BackgroundTransparency=1;body.Position=UDim2.fromOffset(20,160);body.Size=UDim2.new(1,-40,1,-242);body.Parent=panel
local list=Instance.new("ScrollingFrame");list.Name="Weapons";list.BackgroundTransparency=1;list.BorderSizePixel=0
list.Size=UDim2.new(.31,-8,1,0);list.ScrollBarThickness=3;list.ScrollBarImageColor3=colors.accent;list.CanvasSize=UDim2.new();list.AutomaticCanvasSize=Enum.AutomaticSize.Y;list.Parent=body
local listLayout=Instance.new("UIListLayout");listLayout.Padding=UDim.new(0,8);listLayout.SortOrder=Enum.SortOrder.LayoutOrder;listLayout.Parent=list
local listPadding=Instance.new("UIPadding");listPadding.PaddingTop=UDim.new(0,2);listPadding.PaddingLeft=UDim.new(0,2);listPadding.PaddingRight=UDim.new(0,7);listPadding.PaddingBottom=UDim.new(0,3);listPadding.Parent=list
local detail=Instance.new("ScrollingFrame");detail.Name="WeaponDetail";detail.BackgroundColor3=colors.raised;detail.BorderSizePixel=0
detail.Position=UDim2.new(.31,4,0,0);detail.Size=UDim2.new(.69,-4,1,0);detail.ScrollBarThickness=3;detail.ScrollBarImageColor3=colors.accent
detail.CanvasSize=UDim2.new();detail.AutomaticCanvasSize=Enum.AutomaticSize.Y;detail.Parent=body;round(detail,8)
local detailPadding=Instance.new("UIPadding");detailPadding.PaddingLeft=UDim.new(0,14);detailPadding.PaddingRight=UDim.new(0,14);detailPadding.PaddingTop=UDim.new(0,14);detailPadding.PaddingBottom=UDim.new(0,14);detailPadding.Parent=detail
local detailLayout=Instance.new("UIListLayout");detailLayout.Padding=UDim.new(0,9);detailLayout.SortOrder=Enum.SortOrder.LayoutOrder;detailLayout.Parent=detail
local function detailText(name: string,size: number,order: number): TextLabel
    local item=text(detail,name,"",size);item.Size=UDim2.new(1,-6,0,0);item.AutomaticSize=Enum.AutomaticSize.Y;item.LayoutOrder=order;return item
end
local selectedName=detailText("WeaponName",24,1);selectedName.Font=Enum.Font.GothamBold
local selectedRole=detailText("WeaponRole",12,2);selectedRole.TextColor3=colors.gold
local viewport=Instance.new("ViewportFrame");viewport.Name="WeaponPreview";viewport.LayoutOrder=3
viewport.Size=UDim2.new(1,-6,0,220);viewport.BackgroundColor3=Color3.fromRGB(20,30,36);viewport.BorderSizePixel=0;viewport.Parent=detail
round(viewport,6);stroke(viewport,colors.line)
local missing=text(viewport,"AssetMissing","PRÉVIA DO EQUIPAMENTO",12);missing.Size=UDim2.fromScale(1,1)
missing.TextXAlignment=Enum.TextXAlignment.Center;missing.TextYAlignment=Enum.TextYAlignment.Center;missing.TextColor3=colors.muted
local description=detailText("Description",13,4)
local stats=detailText("Stats",12,5);stats.TextColor3=colors.muted
local bars=Instance.new("Frame");bars.Name="Comparison";bars.LayoutOrder=6;bars.Size=UDim2.new(1,-6,0,104);bars.BackgroundTransparency=1;bars.Parent=detail
local comparisons: {[string]: {Fill: Frame,Value: TextLabel}}={}
for index,entry in {{"Damage","DANO / DISPARO"},{"Rate","CADÊNCIA"},{"Reload","TEMPO DE RECARGA"}} do
    local row=Instance.new("Frame");row.Name=entry[1];row.BackgroundTransparency=1;row.Position=UDim2.fromOffset(0,(index-1)*35);row.Size=UDim2.new(1,0,0,29);row.Parent=bars
    local caption=text(row,"Caption",entry[2],10);caption.TextColor3=colors.muted;caption.Size=UDim2.new(.67,0,0,15)
    local value=text(row,"Value","",11);value.Position=UDim2.new(.67,0,0,0);value.Size=UDim2.new(.33,0,0,15)
    local track=Instance.new("Frame");track.Name="Track";track.BorderSizePixel=0;track.BackgroundColor3=colors.line;track.Position=UDim2.fromOffset(0,21);track.Size=UDim2.new(1,0,0,3);track.Parent=row
    local fill=Instance.new("Frame");fill.Name="Fill";fill.BorderSizePixel=0;fill.BackgroundColor3=colors.gold;fill.Size=UDim2.fromScale(0,1);fill.Parent=track
    comparisons[entry[1]]={Fill=fill,Value=value}
end
local selectedStatus=detailText("Ownership",12,7);selectedStatus.TextColor3=colors.accent
local footer=Instance.new("Frame");footer.Name="Actions";footer.BackgroundTransparency=1;footer.Position=UDim2.new(0,20,1,-68);footer.Size=UDim2.new(1,-40,0,52);footer.Parent=panel
local buy=button(footer,"Buy","COMPRAR",13);buy.Size=UDim2.new(.48,-6,0,46)
local equip=button(footer,"Equip","EQUIPAR",12);equip.Position=UDim2.new(.48,2,0,0);equip.Size=UDim2.new(.26,-4,0,46)
local ammo=button(footer,"Ammo","MUNIÇÃO",12);ammo.Position=UDim2.new(.74,4,0,0);ammo.Size=UDim2.new(.26,-4,0,46)
buy.TextWrapped=true;equip.TextWrapped=true;ammo.TextWrapped=true
local cards: {[string]: {Button: TextButton,Price: TextLabel,Stroke: UIStroke,Name: TextLabel,Key: TextLabel}}={}
local maximum={Damage=1,Rate=1,Reload=1}
for _,id in Config.WeaponOrder do
    local item=Config.Weapons[id]
    maximum.Damage=math.max(maximum.Damage,item.Damage*item.Pellets)
    maximum.Rate=math.max(maximum.Rate,60/item.FireInterval)
    maximum.Reload=math.max(maximum.Reload,item.ReloadSeconds)
end
local preview: any=nil
local shownWeapon: string?=nil
local selected=Config.WeaponOrder[1]
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
local function assetReady(id: string): boolean
    local kit=RS:FindFirstChild("ZO_WeaponAssets")
    local weapons=kit and kit:FindFirstChild("Weapons")
    local template=weapons and weapons:FindFirstChild(id)
    return template~=nil and template:IsA("Tool")
end
local function assetFailed(id: string): boolean
    local kit=RS:FindFirstChild("ZO_WeaponAssets")
    local status=kit and kit:GetAttribute("Status_"..id)
    return status=="Failed" or status=="Missing"
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
    local card=button(list,id,"",12);card.Size=UDim2.new(1,-3,0,86);card.LayoutOrder=index
    local border=stroke(card,colors.line)
    local accent=Instance.new("Frame");accent.Name="WeaponColor";accent.Size=UDim2.new(0,4,1,-18);accent.Position=UDim2.fromOffset(7,9)
    accent.BackgroundColor3=Color3.fromRGB(item.Color[1],item.Color[2],item.Color[3]);accent.BorderSizePixel=0;accent.Parent=card
    local name=text(card,"Label",item.Label,14);name.Font=Enum.Font.GothamBold;name.Position=UDim2.fromOffset(18,12);name.Size=UDim2.new(1,-45,0,34)
    local key=text(card,"QuickSelect",tostring(index),11);key.Position=UDim2.new(1,-27,0,13);key.Size=UDim2.fromOffset(18,18);key.TextColor3=colors.muted
    local price=text(card,"Price","",11);price.Position=UDim2.fromOffset(18,55);price.Size=UDim2.new(1,-24,0,22);price.TextColor3=colors.muted
    cards[id]={Button=card,Price=price,Stroke=border,Name=name,Key=key}
    card.Activated:Connect(function() selected=id;message="";refresh() end)
end
local function availabilityText(): (string,Color3)
    if pending then return "Aguardando confirmação do servidor…",colors.gold end
    if not assetReady(selected) then
        local kit=RS:FindFirstChild("ZO_WeaponAssets")
        if kit and kit:GetAttribute("Status_"..selected)=="Missing" then
            return "Modelo ainda não incluído nesta versão.",colors.gold
        end
        return if assetFailed(selected) then "Falha no asset oficial · confira o Output do servidor." else "Modelo indisponível · aguardando os assets oficiais da arma.",colors.gold
    end
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
    if not Config.Weapons[selected] then selected=Config.WeaponOrder[1] end
    local balance=player:GetAttribute("ZO_Credits") or 0
    local primary,secondary=player:GetAttribute("ZO_PrimaryWeapon"),player:GetAttribute("ZO_SecondaryWeapon")
    credits.Text=("CRÉDITOS  $%d"):format(balance)
    inventory.Text=("Primária: %s   |   Secundária: %s\nEm mãos: %s"):format(weaponName(primary),weaponName(secondary),weaponName(player:GetAttribute("ZO_WeaponId")))
    local stateText,stateColor=availabilityText();availability.Text=stateText;availability.TextColor3=stateColor
    local remaining=math.max(0,math.floor(RS:GetAttribute("ZO_Remaining") or 0))
    timer.Text=if soloPractice() then "TREINO" elseif phase()=="Preparation" then ("COMPRA  %02d:%02d"):format(math.floor(remaining/60),remaining%60) else "COMPRA ENCERRADA"
    local item=Config.Weapons[selected]
    local isOwned=owned(selected)
    local modelReady=assetReady(selected)
    for id,card in cards do
        local entry=Config.Weapons[id]
        card.Stroke.Color=if id==selected then colors.accent else colors.line
        card.Stroke.Thickness=if id==selected then 2 else 1
        card.Button.BackgroundColor3=if id==selected then Color3.fromRGB(41,60,58) else colors.raised
        card.Price.Text=if not assetReady(id) then ("$%d · %s"):format(entry.Price,if assetFailed(id) then "MODELO INDISPONÍVEL" else "CARREGANDO MODELO")
            elseif id==player:GetAttribute("ZO_WeaponId") then "EM MÃOS" elseif owned(id) then "NO SEU EQUIPAMENTO" else ("$%d"):format(entry.Price)
    end
    selectedName.Text=item.Label
    local roles={Rifle="Carabina equilibrada",SMG="Defesa móvel a curta distância",Shotgun="Contenção de entradas próximas",Pistol="Secundária de emergência"}
    selectedRole.Text=roles[selected] or (if item.Slot=="Secondary" then "Arma secundária" else "Arma primária")
    description.Text=item.Description
    local damage=if item.Pellets>1 then ("%d × %d projéteis"):format(item.Damage,item.Pellets) else tostring(item.Damage)
    stats.Text=("%d / %d munições  ·  %s  ·  alcance %d"):format(item.Magazine,item.Reserve,if item.Automatic then "AUTOMÁTICA" else "SEMIAUTOMÁTICA",item.Range)
    for key,value in {Damage=item.Damage*item.Pellets,Rate=60/item.FireInterval,Reload=item.ReloadSeconds} do
        comparisons[key].Fill.Size=UDim2.fromScale(math.clamp(value/maximum[key],0,1),1)
    end
    comparisons.Damage.Value.Text=damage
    comparisons.Rate.Value.Text=("%d / min"):format(math.floor(60/item.FireInterval+.5))
    comparisons.Reload.Value.Text=("%.1f s"):format(item.ReloadSeconds)
    if preview and shownWeapon~=selected then preview:setWeapon(selected);shownWeapon=selected end
    selectedStatus.Text=if selected==player:GetAttribute("ZO_WeaponId") then "EQUIPADA · munição atual: "..tostring(player:GetAttribute("ZO_Ammo") or 0).." / "..tostring(player:GetAttribute("ZO_Reserve") or 0)
        elseif isOwned then "NO SEU EQUIPAMENTO · trocar preserva a munição"
        elseif item.Slot=="Primary" then "A compra substitui sua arma primária. A pistola continua com você."
        else "A pistola é a secundária inicial de todo humano."
    buy.Text=if isOwned then "ARMA JÁ ADQUIRIDA" elseif balance<item.Price then ("COMPRAR $%d · faltam $%d"):format(item.Price,item.Price-balance) else ("COMPRAR  $%d"):format(item.Price)
    equip.Text=if selected==player:GetAttribute("ZO_WeaponId") then "EM MÃOS" else "EQUIPAR"
    ammo.Text=("MUNIÇÃO  $%d"):format(Config.Economy.AmmoPrice)
    setEnabled(buy,modelReady and pending==nil and canBuy() and not isOwned and item.Slot=="Primary" and balance>=item.Price)
    setEnabled(equip,modelReady and pending==nil and canEquip() and isOwned and selected~=player:GetAttribute("ZO_WeaponId"))
    setEnabled(ammo,pending==nil and canBuy() and balance>=Config.Economy.AmmoPrice)
    local human=role()=="Humans" and alive()
    touchPrimary.Visible=UIS.TouchEnabled and human and not open and player:GetAttribute("ZO_TacticalMapOpen")~=true
    touchSecondary.Visible=touchPrimary.Visible
    local shortNames={Rifle="CARABINA",SMG="SMG",Shotgun="ESCOPETA",Pistol="PISTOLA"}
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
        message="";selected=if Config.Weapons[player:GetAttribute("ZO_WeaponId")] then player:GetAttribute("ZO_WeaponId") else Config.WeaponOrder[1]
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
    if (action=="Buy" or action=="Equip") and id and Config.Weapons[id] and not assetReady(id) then return end
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
    local narrow=panel.AbsoluteSize.X<600
    title.TextSize=if narrow then 16 else 20
    credits.TextSize=if narrow then 13 else 16
    timer.TextSize=if narrow then 10 else 12
    selectedName.TextSize=if narrow then 19 else 24
    local header=if compact then 109 else 160
    inventory.Visible=not compact
    credits.Position=UDim2.fromOffset(20,if compact then 43 else 50)
    timer.Position=UDim2.new(.55,0,0,if compact then 44 else 52)
    availability.Position=UDim2.fromOffset(20,if compact then 74 else 122)
    body.Position=UDim2.fromOffset(20,header);body.Size=UDim2.new(1,-40,1,-header-82)
    viewport.Size=UDim2.new(1,-6,0,if compact then 110 elseif narrow then 160 else 220)
    local selector=if narrow then .32 else .31
    list.Size=UDim2.new(selector,-8,1,0)
    detail.Position=UDim2.new(selector,4,0,0);detail.Size=UDim2.new(1-selector,-4,1,0)
    for _,card in cards do
        card.Name.TextSize=if narrow then 11 else 14
        card.Name.Size=UDim2.new(1,if narrow then -25 else -45,0,34)
        card.Key.Visible=not narrow and UIS.KeyboardEnabled~=false
        card.Price.TextSize=if narrow then 10 else 11
    end
    buy.TextSize=if narrow then 11 else 13
    equip.TextSize=if narrow then 10 else 12
    ammo.TextSize=if narrow then 10 else 12
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
RS:GetAttributeChangedSignal("ZO_Remaining"):Connect(refresh)
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
task.spawn(function()
    local module=RS.K17Gameplay:FindFirstChild("WeaponPreview")
    if not module then missing.Text="PRÉVIA INDISPONÍVEL";return end
    local ok,result=pcall(function() return require(module).new(viewport) end)
    if not ok then
        missing.Text="PRÉVIA INDISPONÍVEL"
        warn("[K17] Preview do arsenal indisponível: "..tostring(result))
        return
    end
    preview=result;refresh()
end)
local quickKeys={Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Three,Enum.KeyCode.Four,Enum.KeyCode.Five,
    Enum.KeyCode.Six,Enum.KeyCode.Seven,Enum.KeyCode.Eight,Enum.KeyCode.Nine}
CAS:BindActionAtPriority("ZO_ShopSelect",function(_,state: Enum.UserInputState,input: InputObject)
    if not open or UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
    if state==Enum.UserInputState.Begin then
        local index=table.find(quickKeys,input.KeyCode)
        local id=index and Config.WeaponOrder[index]
        if id then selected=id;message="";detail.CanvasPosition=Vector2.new(0,0);refresh() end
    end
    return Enum.ContextActionResult.Sink
end,false,2600,table.unpack(quickKeys))
script.Destroying:Connect(function()
    if open then setOpen(false) end
    if preview then preview:destroy() end
    gui:Destroy()
end)
