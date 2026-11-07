--!nonstrict
-- Presentation of replicated state only; no client combat/economy authority.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local CAS=game:GetService("ContextActionService")
local StarterGui=game:GetService("StarterGui")
local player=Players.LocalPlayer
local shared=RS:WaitForChild("K17Gameplay")
local State=require(shared:WaitForChild("TacticalState"))
local Config=require(shared:WaitForChild("Config"))
local EscapeConfig=require(shared:WaitForChild("EscapeConfig"))
local RouteGuide=require(shared:WaitForChild("RouteGuide"))
local refuges=require(RS:WaitForChild("K17Refuges"))
local playerGui=player:WaitForChild("PlayerGui")
local old=playerGui:FindFirstChild("ZO_RoundHUD");if old then old:Destroy() end
player:SetAttribute("ZO_TacticalHUDReady",false)
local connections={}
local disposed=false
local function connect(signal,callback)
    local c=signal:Connect(callback);table.insert(connections,c);return c
end
local gui=Instance.new("ScreenGui");gui.Name="ZO_RoundHUD";gui.ResetOnSpawn=false
gui.DisplayOrder=5;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.Parent=playerGui
local C={base=Color3.fromRGB(15,23,27),raised=Color3.fromRGB(28,40,44),text=Color3.fromRGB(231,238,231),
    muted=Color3.fromRGB(165,184,181),green=Color3.fromRGB(151,218,179),gold=Color3.fromRGB(235,191,108),red=Color3.fromRGB(241,126,103)}
local function frame(parent,name,pos,size)
    local f=Instance.new("Frame");f.Name=name;f.Position=pos;f.Size=size;f.BackgroundColor3=C.base
    f.BackgroundTransparency=.12;f.BorderSizePixel=0;f.Parent=parent
    local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,6);corner.Parent=f
    return f
end
local function label(parent,name,pos,size,fontSize,color)
    local t=Instance.new("TextLabel");t.Name=name;t.Position=pos;t.Size=size;t.BackgroundTransparency=1
    t.Font=Enum.Font.GothamMedium;t.TextSize=fontSize;t.TextColor3=color or C.text;t.Text=""
    t.TextTruncate=Enum.TextTruncate.AtEnd;t.TextXAlignment=Enum.TextXAlignment.Left;t.Parent=parent
    return t
end
local function bar(parent,name,pos,size,color)
    local back=frame(parent,name,pos,size);back.BackgroundColor3=C.raised;back.ClipsDescendants=true
    local fill=frame(back,"Fill",UDim2.fromScale(0,0),UDim2.fromScale(1,1));fill.BackgroundColor3=color;fill.BackgroundTransparency=0
    return back,fill
end
local top=frame(gui,"RoundHeader",UDim2.new(.5,0,0,8),UDim2.fromOffset(560,66));top.AnchorPoint=Vector2.new(.5,0)
local phaseText=label(top,"Phase",UDim2.fromOffset(14,8),UDim2.new(1,-120,0,20),13,C.green)
local counts=label(top,"Counts",UDim2.fromOffset(14,32),UDim2.new(1,-120,0,24),12,C.muted)
local clockText=label(top,"Clock",UDim2.new(1,-100,0,8),UDim2.fromOffset(86,43),27)
clockText.Font=Enum.Font.RobotoMono;clockText.TextXAlignment=Enum.TextXAlignment.Right
local objective=label(gui,"Objective",UDim2.new(.5,0,0,80),UDim2.fromOffset(670,32),13)
objective.AnchorPoint=Vector2.new(.5,0);objective.TextXAlignment=Enum.TextXAlignment.Center;objective.TextWrapped=true
local zone=label(gui,"Location",UDim2.fromOffset(18,116),UDim2.new(1,-185,0,24),13,C.gold)
local hints=label(gui,"Controls",UDim2.fromOffset(18,142),UDim2.new(1,-36,0,20),11,C.muted)
local version=label(gui,"Version",UDim2.new(1,-205,1,-22),UDim2.fromOffset(190,18),10,C.muted)
version.TextXAlignment=Enum.TextXAlignment.Right
local healthPanel=frame(gui,"Vitals",UDim2.new(0,18,1,-138),UDim2.fromOffset(220,56))
local healthText=label(healthPanel,"Health",UDim2.fromOffset(12,4),UDim2.new(1,-24,0,28),22)
local _,healthFill=bar(healthPanel,"HealthBar",UDim2.new(0,12,1,-13),UDim2.new(1,-24,0,5),C.green)
local wallet=label(gui,"Credits",UDim2.new(0,20,1,-170),UDim2.fromOffset(240,26),15,C.gold)
local ammoPanel=frame(gui,"Equipment",UDim2.new(1,-278,1,-98),UDim2.fromOffset(260,68))
local weaponText=label(ammoPanel,"Weapon",UDim2.fromOffset(12,6),UDim2.new(1,-24,0,18),11,C.muted)
local ammoText=label(ammoPanel,"Ammunition",UDim2.fromOffset(12,24),UDim2.new(1,-24,0,30),24)
ammoText.Font=Enum.Font.RobotoMono;ammoText.TextXAlignment=Enum.TextXAlignment.Right
local reloadBack,reloadFill=bar(ammoPanel,"ReloadProgress",UDim2.new(0,12,1,-9),UDim2.new(1,-24,0,4),C.gold)
local inspector=frame(gui,"Barricade",UDim2.new(.5,0,.5,68),UDim2.fromOffset(330,57));inspector.AnchorPoint=Vector2.new(.5,0);inspector.Visible=false
local propText=label(inspector,"Condition",UDim2.fromOffset(10,4),UDim2.new(1,-20,0,23),12)
local propHint=label(inspector,"Interaction",UDim2.fromOffset(10,28),UDim2.new(1,-20,0,18),10,C.muted)
local _,propFill=bar(inspector,"Resistance",UDim2.new(0,10,1,-6),UDim2.new(1,-20,0,3),C.gold)
local feed=State.feed(4,6)
local feedLabels={}
for i=1,4 do
    local t=label(gui,"CombatReport"..i,UDim2.new(1,-478,0,175+(i-1)*29),UDim2.fromOffset(460,26),11)
    t.TextXAlignment=Enum.TextXAlignment.Right;table.insert(feedLabels,t)
end
local banner=frame(gui,"PhaseAnnouncement",UDim2.new(.5,0,.28,0),UDim2.fromOffset(580,80));banner.AnchorPoint=Vector2.new(.5,0);banner.Visible=false
local bannerTitle=label(banner,"Title",UDim2.fromOffset(16,8),UDim2.new(1,-32,0,28),22,C.gold)
bannerTitle.TextXAlignment=Enum.TextXAlignment.Center
local bannerDetail=label(banner,"Detail",UDim2.fromOffset(16,40),UDim2.new(1,-32,0,30),12)
bannerDetail.TextXAlignment=Enum.TextXAlignment.Center;bannerDetail.TextWrapped=true
local waypoint=Instance.new("BillboardGui");waypoint.Name="EscapeWaypoint";waypoint.Size=UDim2.fromOffset(230,62)
waypoint.StudsOffsetWorldSpace=Vector3.new(0,5,0);waypoint.AlwaysOnTop=true;waypoint.MaxDistance=1000
waypoint.Enabled=false;waypoint.Parent=gui
local waypointText=label(waypoint,"Objective",UDim2.new(),UDim2.fromScale(1,1),13,C.gold)
waypointText.TextWrapped=true;waypointText.TextXAlignment=Enum.TextXAlignment.Center;waypointText.TextStrokeTransparency=.4
local guidePart=Instance.new("Part");guidePart.Name="ZO_EscapeGuidePoint";guidePart.Size=Vector3.new(.1,.1,.1)
guidePart.Transparency=1;guidePart.Anchored=true;guidePart.CanCollide=false;guidePart.CanTouch=false;guidePart.CanQuery=false;guidePart.CastShadow=false
guidePart.Parent=workspace.CurrentCamera
local board=frame(gui,"SessionScoreboard",UDim2.fromScale(.5,.5),UDim2.fromOffset(720,450));board.AnchorPoint=Vector2.new(.5,.5);board.Visible=false
local boardTitle=label(board,"Title",UDim2.fromOffset(18,12),UDim2.new(1,-36,0,28),19,C.gold);boardTitle.Text="K-17 / PLACAR DA SESSÃO"
local boardSummary=label(board,"Summary",UDim2.fromOffset(18,43),UDim2.new(1,-36,0,22),11,C.muted)
local scroll=Instance.new("ScrollingFrame");scroll.Name="Players";scroll.BackgroundTransparency=1;scroll.BorderSizePixel=0
scroll.Position=UDim2.fromOffset(16,78);scroll.Size=UDim2.new(1,-32,1,-120);scroll.ScrollBarThickness=4
scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y;scroll.CanvasSize=UDim2.new();scroll.Parent=board
local layout=Instance.new("UIListLayout");layout.Padding=UDim.new(0,4);layout.Parent=scroll
local boardHint=label(board,"Legend",UDim2.new(0,18,1,-34),UDim2.new(1,-36,0,24),10,C.muted)
boardHint.Text="A: abates de jogadores · I: infecções · Q: quedas · T: treino · dados desta sessão"
local boardButton=Instance.new("TextButton");boardButton.Name="ScoreboardToggle";boardButton.Text="TAB / PLACAR"
boardButton.Font=Enum.Font.GothamMedium;boardButton.TextSize=11;boardButton.TextColor3=C.text;boardButton.BackgroundColor3=C.base
boardButton.BorderSizePixel=0;boardButton.Position=UDim2.new(1,-154,0,118);boardButton.Size=UDim2.fromOffset(136,30);boardButton.Parent=gui
local rows={}
local boardOpen=false
local function showBoard(value)
    if value and (player:GetAttribute("ZO_ShopOpen")==true or player:GetAttribute("ZO_TacticalMapOpen")==true) then return end
    boardOpen=value;board.Visible=value;boardButton.Modal=value;player:SetAttribute("ZO_ScoreboardOpen",value)
end
connect(boardButton.Activated,function()showBoard(not boardOpen)end)
CAS:BindActionAtPriority("ZO_Scoreboard",function(_,state)
    if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
    if state==Enum.UserInputState.Begin then showBoard(true)
    elseif state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel then showBoard(false) end
    return Enum.ContextActionResult.Sink
end,false,3100,Enum.KeyCode.Tab,Enum.KeyCode.DPadLeft)
connect(UIS.WindowFocusReleased,function()showBoard(false)end)
task.spawn(function()
    for _=1,5 do
        if disposed then return end
        if pcall(function()StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,false)end) then break end
        task.wait(.5)
    end
end)
local flash=0
local edges={}
for i=1,4 do
    local edge=frame(gui,"DamageEdge"..i,UDim2.new(),UDim2.new());edge.BackgroundColor3=C.red;edge.Visible=false
    table.insert(edges,edge)
end
edges[1].Size=UDim2.new(1,0,0,9);edges[2].Position=UDim2.new(0,0,1,-9);edges[2].Size=UDim2.new(1,0,0,9)
edges[3].Size=UDim2.new(0,9,1,0);edges[4].Position=UDim2.new(1,-9,0,0);edges[4].Size=UDim2.new(0,9,1,0)
local hum,healthConnection=nil,nil
local function bindHumanoid(character)
    if healthConnection then healthConnection:Disconnect();healthConnection=nil end
    hum=nil;flash=0
    local found=character:WaitForChild("Humanoid",10)
    if disposed or not found or player.Character~=character then return end
    hum=found;local last=found.Health
    healthConnection=found.HealthChanged:Connect(function(value)
        if value<last then flash=math.clamp(flash+(last-value)/math.max(1,found.MaxHealth)*3,.25,.8) end
        last=value
    end)
end
connect(player.CharacterAdded,function(character)task.spawn(bindHumanoid,character)end)
connect(player.CharacterRemoving,function()
    if healthConnection then healthConnection:Disconnect();healthConnection=nil end
    hum=nil;flash=0
end)
if player.Character then task.spawn(bindHumanoid,player.Character) end
local announcementKey=""
local bannerUntil=0
task.spawn(function()
    local remote=RS:WaitForChild("ZO_CombatFX",20)
    if disposed or not remote then return end
    connect(remote.OnClientEvent,function(kind,event)
        if kind~="Report" then return end
        local line=State.report(event,Config.Weapons)
        if line then feed:push(line,os.clock(),event.ActorId==player.UserId) end
    end)
end)
local rayParams=RaycastParams.new();rayParams.FilterType=Enum.RaycastFilterType.Exclude
local function inspect(camera,root,active,zombie)
    inspector.Visible=false
    if not root or not active then return end
    rayParams.FilterDescendantsInstances={player.Character,camera}
    local ray=camera:ViewportPointToRay(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
    local hit=workspace:Raycast(ray.Origin,ray.Direction*18,rayParams)
    if not hit or (hit.Position-root.Position).Magnitude>12 then return end
    local prop=hit.Instance:FindFirstAncestorOfClass("Model")
    if not prop or prop.Parent~=workspace:FindFirstChild("ZO_Barricades") or prop:GetAttribute("ZO_Destroyed")==true then return end
    local health,maximum=prop:GetAttribute("ZO_Health"),prop:GetAttribute("ZO_MaxHealth")
    if type(health)~="number" or type(maximum)~="number" then return end
    propText.Text=("%s   %d / %d"):format(prop:GetAttribute("ZO_Label") or "Barricada",health,maximum)
    propHint.Text=if zombie then "Ataque para romper · procure também o flanco" else "Tiros deslocam o objeto · vigie a outra entrada"
    propFill.Size=UDim2.fromScale(State.ratio(health,maximum),1);inspector.Visible=true
end
local function scoreboard()
    local data={}
    for _,other in Players:GetPlayers() do
        table.insert(data,{Id=other.UserId,Player=other,Name=other.DisplayName,Role=if other.Team then other.Team.Name else "Lobby",
            Kills=other:GetAttribute("ZO_SessionKills") or 0,Infections=other:GetAttribute("ZO_SessionInfections") or 0})
    end
    local present={}
    for i,entry in State.order(data) do
        local other=entry.Player;present[entry.Id]=true
        local row=rows[entry.Id]
        if not row then
            local f=frame(scroll,"Player"..entry.Id,UDim2.new(),UDim2.new(1,-6,0,42))
            row={frame=f,label=label(f,"Info",UDim2.fromOffset(10,0),UDim2.new(1,-20,1,0),11)};rows[entry.Id]=row
        end
        row.frame.LayoutOrder=i;row.frame.BackgroundColor3=if other==player then C.raised else C.base
        row.label.TextColor3=if entry.Role=="Zombies" then C.red elseif entry.Role=="Humans" then C.green else C.muted
        row.label.Text=("%s / %s    A %d  I %d  Q %d  T %d"):format(entry.Name,
            if entry.Role=="Humans" then "HUMANO" elseif entry.Role=="Zombies" then "ZUMBI" else "AGUARDANDO",
            entry.Kills,entry.Infections,other:GetAttribute("ZO_SessionDeaths") or 0,other:GetAttribute("ZO_SessionTrainingKills") or 0)
    end
    for id,row in rows do if not present[id] then row.frame:Destroy();rows[id]=nil end end
    boardSummary.Text=("Você: %d defesas vencidas · %d abates de treino · créditos %d"):format(
        player:GetAttribute("ZO_SessionSurvived") or 0,player:GetAttribute("ZO_SessionTrainingKills") or 0,player:GetAttribute("ZO_Credits") or 0)
end
local accumulator,boardAccumulator=0,0
connect(Run.RenderStepped,function(dt)
    flash=math.max(0,flash-dt*1.8)
    local low=hum and hum.Health>0 and State.ratio(hum.Health,hum.MaxHealth)<.25
    for _,edge in edges do edge.Visible=flash>0 or low==true;edge.BackgroundTransparency=1-math.max(flash,if low then .16 else 0) end
    accumulator+=dt;boardAccumulator+=dt;if accumulator<.1 then return end;accumulator=0
    local camera=workspace.CurrentCamera;if not camera then return end
    local width=camera.ViewportSize.X;local compact=width<760
    local modal=player:GetAttribute("ZO_ShopOpen")==true or player:GetAttribute("ZO_TacticalMapOpen")==true
    if modal and boardOpen then showBoard(false) end
    top.Size=UDim2.fromOffset(math.min(560,width-24),66);objective.Size=UDim2.fromOffset(math.min(670,width-28),32)
    banner.Size=UDim2.fromOffset(math.min(580,width-28),80);board.Size=UDim2.fromOffset(math.min(720,width-24),math.min(450,camera.ViewportSize.Y-40))
    boardButton.Text=if UIS.TouchEnabled then "PLACAR" else "TAB / PLACAR"
    for i,t in feedLabels do
        t.Visible=not modal and not boardOpen
        t.Size=UDim2.fromOffset(math.min(460,width-36),26);t.Position=UDim2.new(1,-math.min(478,width-18),0,175+(i-1)*29)
    end
    local phase=RS:GetAttribute("ZO_RoundState") or "Starting"
    local role=if player.Team then player.Team.Name else "Lobby";local zombie=role=="Zombies"
    local stage=RS:GetAttribute("ZO_TrainingStage");local alive=hum~=nil and hum.Health>0
    local mode=RS:GetAttribute("ZO_RoundMode") or "Survival"
    local escapeStatus=RS:GetAttribute("ZO_EscapeStatus")
    local escapeStage=RS:GetAttribute("ZO_EscapeStage") or 1
    local active=(phase=="Training" or phase=="Preparation" or phase=="Active") and alive and (role=="Humans" or zombie)
    local instruction,title=State.objective(phase,role,RS:GetAttribute("ZO_LastWinner"),stage)
    local seconds=math.max(0,math.ceil((if phase=="Training" then RS:GetAttribute("ZO_TrainingRemaining") else RS:GetAttribute("ZO_Remaining")) or 0))
    if mode=="Escape" and phase=="Active" then
        title=if zombie then "ZE / Interrompa a fuga" else "ZE / Evacuação"
        local target=RS:GetAttribute("ZO_EscapeLabel") or "Objetivo"
        local waitTime=RS:GetAttribute("ZO_EscapeRemaining") or 0
        if escapeStatus=="Holding" then instruction=("Defenda por %ds · %s"):format(waitTime,target);seconds=waitTime
        elseif escapeStatus=="Extraction" then
            instruction=("ENTRE NO TERMINAL · %d humanos na área · extração em %ds"):format(RS:GetAttribute("ZO_EscapeInside") or 0,waitTime);seconds=waitTime
        else instruction=("%d/3 · %s · acione o painel no local"):format(escapeStage,target) end
        if zombie then instruction="Impeça os humanos de extrair · "..instruction end
    elseif mode=="Escape" and phase=="Preparation" then
        title="ZE / Preparação";instruction="Equipe-se · siga os objetivos após a primeira infecção"
    elseif mode=="Escape" and phase=="Results" then
        title="ZE / Resultado"
        instruction=if RS:GetAttribute("ZO_LastWinner")=="Humans" then ("Extração concluída · %d humanos escaparam"):format(RS:GetAttribute("ZO_LastEscaped") or 0)
            elseif RS:GetAttribute("ZO_LastWinner")=="Zombies" then "Fuga interrompida · vitória dos zumbis" else "Rodada cancelada"
    elseif mode=="Survival" and (phase=="Active" or phase=="Preparation" or phase=="Results") then title="ZM / "..title end
    phaseText.Text=string.upper(title);phaseText.TextColor3=if zombie then C.red else C.green
    clockText.Text=("%02d:%02d"):format(math.floor(seconds/60),seconds%60);clockText.TextColor3=if phase=="Active" and seconds<=15 then C.red else C.text
    counts.Text=if phase=="Training" then ("ONDA %d/3 · ABATES %d · VIVOS %d"):format(
        RS:GetAttribute("ZO_TrainingWave") or 1,RS:GetAttribute("ZO_TrainingKills") or 0,RS:GetAttribute("ZO_TrainingAlive") or 0)
        else ("HUMANOS %d / ZUMBIS %d"):format(RS:GetAttribute("ZO_Humans") or 0,RS:GetAttribute("ZO_Zombies") or 0)
    local errorMessage=RS:GetAttribute("ZO_GameplayError") or (if phase=="Training" then RS:GetAttribute("ZO_TrainingError") else nil)
    if errorMessage then instruction="FALHA: "..tostring(errorMessage);objective.TextColor3=C.red
    elseif phase=="Starting" then instruction="Iniciando · "..tostring(RS:GetAttribute("ZO_StartupStep") or "Aguardando servidor");objective.TextColor3=C.muted
    else objective.TextColor3=C.text end
    objective.Text=instruction;version.Text="ZOMBIE OUTBREAK / v"..tostring(RS:GetAttribute("ZO_Version") or "0.4.0")
    local key=phase..":"..mode..":"..tostring(escapeStatus)..":"..escapeStage..":"..tostring(stage)..":"..tostring(RS:GetAttribute("ZO_TrainingWave"))..":"..role
    if key~=announcementKey then announcementKey=key;bannerUntil=os.clock()+3;bannerTitle.Text=string.upper(title);bannerDetail.Text=instruction end
    banner.Visible=not modal and not boardOpen and os.clock()<bannerUntil and phase~="Waiting" and phase~="Starting"
    healthPanel.Visible=active and not modal;ammoPanel.Visible=active and not modal;wallet.Visible=active and not modal
    healthPanel.Size=UDim2.fromOffset(if compact then 176 else 220,56);ammoPanel.Size=UDim2.fromOffset(if compact then 200 else 260,68)
    ammoPanel.Position=UDim2.new(1,if compact then -218 else -278,1,if UIS.TouchEnabled then -268 else -98)
    local currentHealth=if hum then math.ceil(hum.Health) else 0
    healthText.Text=("%s  %d"):format(if zombie then "ZUMBI" else "VIDA",currentHealth)
    local ratio=State.ratio(currentHealth,if hum then hum.MaxHealth else 100)
    healthFill.Size=UDim2.fromScale(ratio,1);healthFill.BackgroundColor3=if ratio<.25 then C.red elseif zombie then C.gold else C.green
    wallet.Text=("$ %d"):format(player:GetAttribute("ZO_Credits") or 0)
    local weapon=Config.Weapons[player:GetAttribute("ZO_WeaponId")] or Config.Weapons.Rifle
    local clip=player:GetAttribute("ZO_Ammo") or 0;local reload=player:GetAttribute("ZO_Reloading")==true
    local remaining=math.max(0,(player:GetAttribute("ZO_ReloadEndsAt") or 0)-workspace:GetServerTimeNow())
    local equip=workspace:GetServerTimeNow()<(player:GetAttribute("ZO_EquipReadyAt") or 0)
    weaponText.Text=if zombie then "INFECÇÃO / COMBATE PRÓXIMO" else string.upper(weapon.Label).." / "..(if weapon.Slot=="Primary" then "PRIMÁRIA" else "SECUNDÁRIA")
    ammoText.Text=if zombie then "GARRAS" elseif reload then ("RECARGA %.1fs"):format(remaining) elseif equip then "EQUIPANDO"
        else ("%02d / %03d"):format(clip,player:GetAttribute("ZO_Reserve") or 0)
    ammoText.TextColor3=if not zombie and clip<=weapon.Magazine*.2 then C.gold else C.text
    reloadBack.Visible=reload and not zombie;reloadFill.Size=UDim2.fromScale(1-State.ratio(remaining,weapon.ReloadSeconds),1)
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    waypoint.Enabled=false
    if mode=="Escape" and phase=="Active" and not modal and not boardOpen and root and player:GetAttribute("ZO_Spectating")~=true then
        local map=workspace:FindFirstChild("ZO_K17Foundry")
        local controls=map and map:FindFirstChild("EscapeObjectives")
        local bay=map and map:FindFirstChild("R50_EvacuationBay")
        local target=if escapeStatus=="Extraction" then bay and bay:FindFirstChild("EvacuationGate")
            else controls and controls:FindFirstChild("Control"..escapeStage)
        if target then
            waypoint.Adornee=target;waypoint.Enabled=true
            local destination=target.Position
            local detail="Acione o painel"
            local path=EscapeConfig.Paths and EscapeConfig.Paths[escapeStage]
            if escapeStatus~="Extraction" and path and (target.Position-root.Position).Magnitude>10 then
                local p,hint=RouteGuide.next(path,{root.Position.X,root.Position.Y-3,root.Position.Z},3)
                destination=Vector3.new(p[1],p[2]+3,p[3]);guidePart.Position=destination;guidePart.Parent=camera
                waypoint.Adornee=guidePart;detail=hint
            end
            waypointText.Text=("%s\n%s · %.0f studs"):format(if escapeStatus=="Extraction" then "EXTRAÇÃO / ENTRE NO TERMINAL" else EscapeConfig.Stages[escapeStage].Label,
                if escapeStatus=="Extraction" then "Entre e defenda" else detail,(destination-root.Position).Magnitude)
        end
    end
    zone.Text=if root then State.zone(refuges,root.Position.X,root.Position.Y,root.Position.Z) else "K-17 / carregando personagem"
    hints.Text=if UIS.TouchEnabled then "Mapa e arsenal nos botões da tela" elseif zombie then "Clique: atacar · M: mapa · Tab: placar" else "B: arsenal · R: recarga · 1/2: armas · M: mapa"
    if mode=="Escape" and phase=="Active" and escapeStatus=="Ready" then
        hints.Text=EscapeConfig.Stages[escapeStage].Hint or hints.Text
    elseif mode=="Escape" and phase=="Active" and escapeStatus=="Holding" then
        local gate=RS:GetAttribute("ZO_HoldGateStatus")
        if gate=="Closed" then hints.Text="Saída em retenção · defenda os flancos até liberar"
        elseif gate=="Blocked" then hints.Text="Retenção aguarda passagem livre · mantenha os flancos" end
    end
    inspect(camera,root,active and not modal and not boardOpen,zombie)
    feed:expire(os.clock())
    for i,t in feedLabels do local item=feed.items[i];t.Text=if item then item.text else "";t.TextColor3=if item and item.accent then C.gold else C.text end
    if boardOpen and boardAccumulator>=.4 then boardAccumulator=0;scoreboard() end
    player:SetAttribute("ZO_TacticalHUDReady",true)
end)
gui.Destroying:Connect(function()
    disposed=true
    player:SetAttribute("ZO_TacticalHUDReady",false);player:SetAttribute("ZO_ScoreboardOpen",false);CAS:UnbindAction("ZO_Scoreboard")
    if healthConnection then healthConnection:Disconnect() end
    guidePart:Destroy()
    for _,c in connections do c:Disconnect() end
    pcall(function()StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,true)end)
end)
