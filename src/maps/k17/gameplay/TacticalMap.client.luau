--!strict
-- Original K-17 floor plan. Only static shelter information and the local player are shown.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local CAS = game:GetService("ContextActionService")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

type Refuge = {
    Id: number, Label: string, Model: string, Floor: number, Position: Vector3,
    Bounds: {number}, Props: number, Style: string, Entrances: number?,
}

local source = RS:WaitForChild("K17Refuges", 12)
if not source or not source:IsA("ModuleScript") then
    warn("[K-17] O mapa de refúgios não está disponível nesta versão.")
    return
end
local loaded, raw = pcall(require, source)
if not loaded or type(raw) ~= "table" then
    warn("[K-17] Não foi possível ler o mapa de refúgios.")
    return
end
local function finite(value: any): boolean
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end
local refuges: {Refuge} = {}
local styles: {string} = {"Todos os tipos"}
local seenStyles: {[string]: boolean} = {}
for id, item in raw do
    if type(id) ~= "number" or type(item) ~= "table" then continue end
    local position, bounds = item.Position, item.Bounds
    if type(position) ~= "table" or type(bounds) ~= "table" then continue end
    if not finite(position[1]) or not finite(position[2]) or not finite(position[3]) then continue end
    if not finite(bounds[1]) or not finite(bounds[2]) or not finite(bounds[3]) or not finite(bounds[4]) then continue end
    local style = if type(item.Style) == "string" then item.Style else "Refúgio"
    local floor = if finite(item.Floor) then item.Floor else position[2]
    local refuge: Refuge = {
        Id = id, Label = tostring(item.Label or ("Refúgio " .. id)), Model = tostring(item.Model or ""),
        Floor = floor, Position = Vector3.new(position[1], position[2], position[3]),
        Bounds = {bounds[1], bounds[2], bounds[3], bounds[4]},
        Props = if finite(item.Props) then math.max(0, math.floor(item.Props)) else 0,
        Style = style, Entrances = if finite(item.Entrances) then math.max(0, math.floor(item.Entrances)) else nil,
    }
    table.insert(refuges, refuge)
    if not seenStyles[style] then
        seenStyles[style] = true
        table.insert(styles, style)
    end
end
if #refuges == 0 then
    warn("[K-17] Nenhum refúgio foi encontrado no mapa tático.")
    return
end
table.sort(refuges, function(a: Refuge, b: Refuge) return a.Id < b.Id end)
table.sort(styles, function(a: string, b: string)
    if a == b then return false end
    if a == "Todos os tipos" then return true end
    if b == "Todos os tipos" then return false end
    return a < b
end)

local colors = {
    base = Color3.fromRGB(14, 21, 25), raised = Color3.fromRGB(23, 33, 38),
    line = Color3.fromRGB(60, 77, 80), text = Color3.fromRGB(236, 241, 232),
    muted = Color3.fromRGB(164, 182, 180), accent = Color3.fromRGB(151, 218, 182),
    gold = Color3.fromRGB(233, 196, 123), underground = Color3.fromRGB(159, 176, 219),
}
local gui = Instance.new("ScreenGui")
gui.Name = "ZO_TacticalMap"
gui.DisplayOrder = 40
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function round(parent: GuiObject, radius: number)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
end
local function outline(parent: GuiObject, color: Color3, transparency: number?): UIStroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Transparency = transparency or 0
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end
local function text(parent: Instance, name: string, value: string, size: number): TextLabel
    local label = Instance.new("TextLabel")
    label.Name = name
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.Text = value
    label.TextSize = size
    label.TextColor3 = colors.text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.Parent = parent
    return label
end
local function button(parent: Instance, name: string, value: string, size: number): TextButton
    local item = Instance.new("TextButton")
    item.Name = name
    item.BackgroundColor3 = colors.raised
    item.BorderSizePixel = 0
    item.Font = Enum.Font.GothamMedium
    item.TextColor3 = colors.text
    item.TextSize = size
    item.Text = value
    item.AutoButtonColor = true
    item.Parent = parent
    round(item, 7)
    return item
end

local toggle = button(gui, "OpenMap", "M  MAPA", 13)
toggle.AnchorPoint = Vector2.new(1, 1)
toggle.Position = UDim2.new(1, -22, 1, -24)
toggle.Size = UDim2.fromOffset(116, 42)
toggle.ZIndex = 60
outline(toggle, colors.accent, .4)

local shade = button(gui, "Backdrop", "", 1)
shade.Size = UDim2.fromScale(1, 1)
shade.BackgroundColor3 = Color3.new(0, 0, 0)
shade.BackgroundTransparency = .25
shade.AutoButtonColor = false
shade.Modal = true -- Releases the mouse while the first-person camera remains active.
shade.Visible = false
shade.ZIndex = 20

local panel = Instance.new("Frame")
panel.Name = "FloorPlan"
panel.AnchorPoint = Vector2.new(.5, .5)
panel.Position = UDim2.fromScale(.5, .5)
panel.Size = UDim2.fromScale(.95, .92)
panel.BackgroundColor3 = colors.base
panel.BorderSizePixel = 0
panel.Visible = false
panel.Active = true
panel.ZIndex = 30
panel.Parent = gui
round(panel, 12)
outline(panel, colors.line)
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(1120, 780)
limit.Parent = panel
local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 16)
padding.PaddingRight = UDim.new(0, 16)
padding.PaddingTop = UDim.new(0, 14)
padding.PaddingBottom = UDim.new(0, 12)
padding.Parent = panel

local title = text(panel, "Title", "K-17  /  MAPA DE REFÚGIOS", 19)
title.Font = Enum.Font.GothamBold
title.Position = UDim2.fromOffset(0, 0)
title.Size = UDim2.new(1, -56, 0, 26)
local subtitle = text(panel, "Subtitle", "Escolha um abrigo e reconheça as rotas antes da infecção.", 12)
subtitle.Position = UDim2.fromOffset(0, 30)
subtitle.Size = UDim2.new(1, -4, 0, 20)
subtitle.TextColor3 = colors.muted
local close = button(panel, "Close", "×", 25)
close.AnchorPoint = Vector2.new(1, 0)
close.Position = UDim2.new(1, 0, 0, -4)
close.Size = UDim2.fromOffset(42, 38)

local controls = Instance.new("Frame")
controls.Name = "Filters"
controls.BackgroundTransparency = 1
controls.Position = UDim2.fromOffset(0, 60)
controls.Size = UDim2.new(1, 0, 0, 36)
controls.Parent = panel
local floorButton = button(controls, "Floor", "Piso: todos  ›", 12)
floorButton.Size = UDim2.new(.43, -4, 1, 0)
local styleButton = button(controls, "Type", "Todos os tipos  ›", 12)
styleButton.Position = UDim2.new(.43, 4, 0, 0)
styleButton.Size = UDim2.new(.57, -4, 1, 0)
styleButton.TextTruncate = Enum.TextTruncate.AtEnd

local body = Instance.new("Frame")
body.Name = "Content"
body.BackgroundTransparency = 1
body.Position = UDim2.fromOffset(0, 108)
body.Size = UDim2.new(1, 0, 1, -132)
body.Parent = panel
local mapRegion = Instance.new("Frame")
mapRegion.Name = "MapRegion"
mapRegion.BackgroundTransparency = 1
mapRegion.Parent = body
local map = Instance.new("Frame")
map.Name = "ComplexPlan"
map.AnchorPoint = Vector2.new(.5, .5)
map.Position = UDim2.fromScale(.5, .5)
map.Size = UDim2.fromScale(1, 1)
map.BackgroundColor3 = Color3.fromRGB(27, 39, 42)
map.BorderSizePixel = 0
map.ClipsDescendants = true
map.Parent = mapRegion
round(map, 8)
outline(map, colors.line)
local aspect = Instance.new("UIAspectRatioConstraint")
aspect.AspectRatio = 1
aspect.AspectType = Enum.AspectType.FitWithinMaxSize
aspect.Parent = map

-- The plan is a 600 x 600 stud view of the authored complex, with north at -Z.
local function uv(x: number, z: number): UDim2
    return UDim2.fromScale((x + 300) / 600, (z + 300) / 600)
end
local function rectangle(name: string, bounds: {number}, color: Color3, transparency: number): Frame
    local item = Instance.new("Frame")
    item.Name = name
    item.Position = uv(bounds[1], bounds[3])
    item.Size = UDim2.fromScale((bounds[2] - bounds[1]) / 600, (bounds[4] - bounds[3]) / 600)
    item.BackgroundColor3 = color
    item.BackgroundTransparency = transparency
    item.BorderSizePixel = 0
    item.Parent = map
    return item
end
for coordinate = -250, 250, 50 do
    rectangle("GridX", {coordinate, coordinate + .65, -300, 300}, colors.line, .7)
    rectangle("GridZ", {-300, 300, coordinate, coordinate + .65}, colors.line, .7)
end
rectangle("CentralYard", {-162, 162, -120, 60}, Color3.fromRGB(59, 72, 69), .4)
local buildings = {
    {Label = "ADMINISTRAÇÃO", Bounds = {-148, 12, -250, -124}},
    {Label = "ENERGIA", Bounds = {40, 248, -250, -124}},
    {Label = "ARMAZÉM", Bounds = {-264, -170, -68, 148}},
    {Label = "FUNDIÇÃO", Bounds = {-142, 124, 68, 246}},
    {Label = "TORRE", Bounds = {172, 248, -36, 76}},
}
for _, building in buildings do
    local footprint = rectangle(building.Label, building.Bounds, Color3.fromRGB(79, 99, 96), .32)
    outline(footprint, Color3.fromRGB(113, 133, 128), .7)
    local name = text(footprint, "Name", building.Label, 9)
    name.TextXAlignment = Enum.TextXAlignment.Center
    name.TextColor3 = colors.muted
    name.Position = UDim2.new(0, 2, 0, 3)
    name.Size = UDim2.new(1, -4, 0, 20)
    name.TextScaled = true
    local fontLimit = Instance.new("UITextSizeConstraint")
    fontLimit.MinTextSize = 6
    fontLimit.MaxTextSize = 9
    fontLimit.Parent = name
end
local north = text(map, "North", "↑ N", 13)
north.Position = UDim2.fromOffset(10, 8)
north.Size = UDim2.fromOffset(34, 20)
north.TextColor3 = colors.muted
local selectionArea = rectangle("SelectedShelter", {-1, 1, -1, 1}, colors.accent, .75)
selectionArea.ZIndex = 3
selectionArea.Visible = false
outline(selectionArea, colors.accent)

local sidebar = Instance.new("Frame")
sidebar.Name = "Shelters"
sidebar.BackgroundTransparency = 1
sidebar.Parent = body
local detail = Instance.new("Frame")
detail.Name = "SelectedShelter"
detail.BackgroundColor3 = colors.raised
detail.BorderSizePixel = 0
detail.Parent = sidebar
round(detail, 8)
local detailPad = Instance.new("UIPadding")
detailPad.PaddingLeft = UDim.new(0, 12)
detailPad.PaddingRight = UDim.new(0, 12)
detailPad.PaddingTop = UDim.new(0, 10)
detailPad.PaddingBottom = UDim.new(0, 8)
detailPad.Parent = detail
local selectedTitle = text(detail, "Title", "Escolha um refúgio", 15)
selectedTitle.Font = Enum.Font.GothamBold
selectedTitle.Size = UDim2.new(1, 0, 0, 40)
selectedTitle.TextWrapped = true
local selectedInfo = text(detail, "Facts", "", 12)
selectedInfo.Position = UDim2.fromOffset(0, 45)
selectedInfo.Size = UDim2.new(1, 0, 0, 54)
selectedInfo.TextWrapped = true
selectedInfo.TextColor3 = colors.muted
local selectedDistance = text(detail, "Distance", "", 12)
selectedDistance.Position = UDim2.fromOffset(0, 106)
selectedDistance.Size = UDim2.new(1, 0, 0, 32)
selectedDistance.TextWrapped = true
selectedDistance.TextColor3 = colors.accent
local list = Instance.new("ScrollingFrame")
list.Name = "ShelterList"
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 4
list.ScrollBarImageColor3 = colors.accent
list.ScrollingDirection = Enum.ScrollingDirection.Y
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.fromOffset(0, 0)
list.Parent = sidebar
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = list
local listPadding = Instance.new("UIPadding")
listPadding.PaddingRight = UDim.new(0, 8)
listPadding.PaddingBottom = UDim.new(0, 4)
listPadding.Parent = list
local empty = text(list, "NoMatches", "Nenhum refúgio neste filtro.\nExperimente outro piso ou tipo.", 12)
empty.TextWrapped = true
empty.Size = UDim2.new(1, -8, 0, 56)
empty.TextColor3 = colors.muted
empty.Visible = false
local legend = text(panel, "Legend", "● Você    /    números: refúgios    /    M: fechar", 11)
legend.AnchorPoint = Vector2.new(0, 1)
legend.Position = UDim2.fromScale(0, 1)
legend.Size = UDim2.new(1, 0, 0, 16)
legend.TextColor3 = colors.muted

local you = Instance.new("Frame")
you.Name = "YourPosition"
you.AnchorPoint = Vector2.new(.5, .5)
you.Size = UDim2.fromOffset(10, 10)
you.BackgroundColor3 = Color3.fromRGB(245, 248, 243)
you.BorderSizePixel = 0
you.ZIndex = 7
you.Visible = false
you.Parent = map
round(you, 5)
outline(you, colors.base)

local floorLabels = {"Todos", "Térreo", "2º andar", "3º andar", "4º andar", "Subterrâneo", "Contêiner elevado"}
local floorIndex, styleIndex = 1, 1
local selected: Refuge? = nil
local markers: {[number]: TextButton} = {}
local rows: {[number]: TextButton} = {}
local visibleCount = 0
local function positionLevel(footHeight: number, position: Vector3): number
    if footHeight < -4 then return 6 end
    local container = position.X >= -145 and position.X <= -14 and position.Z >= -122 and position.Z <= -75
    if container and footHeight >= 9 and footHeight <= 23 then return 7 end
    if footHeight >= 36 then return 5 end
    if footHeight >= 22 then return 4 end
    if footHeight >= 8 then return 3 end
    return 2
end
local function level(refuge: Refuge): number
    return positionLevel(refuge.Floor, refuge.Position)
end
local function floorName(refuge: Refuge): string
    return floorLabels[level(refuge)]
end
local function matches(refuge: Refuge): boolean
    return (floorIndex == 1 or level(refuge) == floorIndex)
        and (styleIndex == 1 or refuge.Style == styles[styleIndex])
end
local function markerColor(refuge: Refuge): Color3
    local floor = level(refuge)
    return if floor == 6 then colors.underground elseif floor ~= 2 then colors.gold else colors.accent
end
local function selectRefuge(refuge: Refuge)
    selected = refuge
    selectedTitle.Text = ("%02d  %s"):format(refuge.Id, refuge.Label)
    local entrances = if refuge.Entrances and refuge.Entrances > 0 then
        (" · %d %s"):format(refuge.Entrances, if refuge.Entrances == 1 then "entrada" else "entradas") else ""
    selectedInfo.Text = ("%s\n%s%s\n%d objetos de barricada"):format(floorName(refuge), refuge.Style, entrances, refuge.Props)
    local bounds = refuge.Bounds
    selectionArea.Position = uv(bounds[1], bounds[3])
    selectionArea.Size = UDim2.fromScale((bounds[2] - bounds[1]) / 600, (bounds[4] - bounds[3]) / 600)
    selectionArea.Visible = true
    for _, item in refuges do
        local active = item.Id == refuge.Id
        local marker = markers[item.Id]
        marker.BackgroundColor3 = if active then colors.text else markerColor(item)
        marker.TextColor3 = colors.base
        marker.Size = UDim2.fromOffset(if active then 25 else 21, if active then 25 else 21)
        marker.ZIndex = if active then 6 else 5
        rows[item.Id].BackgroundColor3 = if active then Color3.fromRGB(53, 78, 68) else colors.raised
    end
end
for _, refuge in refuges do
    local marker = button(map, "Refuge" .. refuge.Id, tostring(refuge.Id), 11)
    marker.AnchorPoint = Vector2.new(.5, .5)
    marker.Position = uv(refuge.Position.X, refuge.Position.Z)
    marker.Size = UDim2.fromOffset(21, 21)
    marker.BackgroundColor3 = markerColor(refuge)
    marker.TextColor3 = colors.base
    marker.ZIndex = 5
    markers[refuge.Id] = marker
    local row = button(list, "Refuge" .. refuge.Id, "", 12)
    row.Size = UDim2.new(1, -8, 0, 58)
    row.LayoutOrder = refuge.Id
    rows[refuge.Id] = row
    local number = text(row, "Number", ("%02d"):format(refuge.Id), 18)
    number.Position = UDim2.fromOffset(10, 17)
    number.Size = UDim2.fromOffset(32, 24)
    number.Font = Enum.Font.GothamBold
    number.TextColor3 = markerColor(refuge)
    local rowTitle = text(row, "Title", refuge.Label, 12)
    rowTitle.Position = UDim2.fromOffset(48, 8)
    rowTitle.Size = UDim2.new(1, -56, 0, 27)
    rowTitle.TextWrapped = true
    rowTitle.Font = Enum.Font.GothamMedium
    local summary = text(row, "Summary", ("%s · %d objetos"):format(floorName(refuge), refuge.Props), 10)
    summary.Position = UDim2.fromOffset(48, 38)
    summary.Size = UDim2.new(1, -56, 0, 15)
    summary.TextColor3 = colors.muted
    row.Activated:Connect(function() selectRefuge(refuge) end)
    marker.Activated:Connect(function() selectRefuge(refuge) end)
end
local function refreshFilter()
    visibleCount = 0
    local first: Refuge? = nil
    for _, refuge in refuges do
        local visible = matches(refuge)
        markers[refuge.Id].Visible = visible
        rows[refuge.Id].Visible = visible
        if visible then
            visibleCount += 1
            if not first then first = refuge end
        end
    end
    floorButton.Text = "Piso: " .. string.lower(floorLabels[floorIndex]) .. "  ›"
    styleButton.Text = styles[styleIndex] .. "  ›"
    subtitle.Text = ("%d de %d refúgios · selecione um número ou uma posição na lista."):format(visibleCount, #refuges)
    empty.Visible = visibleCount == 0
    list.CanvasPosition = Vector2.zero
    if selected and matches(selected) then
        selectionArea.Visible = true
    elseif first then
        selectRefuge(first)
    else
        selected = nil
        selectionArea.Visible = false
        selectedTitle.Text = "Nenhum refúgio neste filtro"
        selectedInfo.Text = "Troque o piso ou o tipo para explorar outras opções."
        selectedDistance.Text = ""
    end
end
floorButton.Activated:Connect(function()
    floorIndex = floorIndex % #floorLabels + 1
    refreshFilter()
end)
styleButton.Activated:Connect(function()
    styleIndex = styleIndex % #styles + 1
    refreshFilter()
end)

local function resize()
    local size = panel.AbsoluteSize
    local portrait = size.X < 620 and size.Y > size.X
    local short = size.Y < 480
    local header = if short then 42 else 60
    title.TextSize = if size.X < 500 then 15 else 19
    subtitle.Visible = not short
    controls.Position = UDim2.fromOffset(0, header)
    body.Position = UDim2.fromOffset(0, header + 46)
    body.Size = UDim2.new(1, 0, 1, -(header + 70))
    if portrait then
        mapRegion.Position = UDim2.fromScale(0, 0)
        mapRegion.Size = UDim2.new(1, 0, .57, -8)
        sidebar.Position = UDim2.fromScale(0, .57)
        sidebar.Size = UDim2.fromScale(1, .43)
        detail.Position = UDim2.fromScale(0, 0)
        detail.Size = UDim2.new(.46, -5, 1, 0)
        list.Position = UDim2.new(.46, 5, 0, 0)
        list.Size = UDim2.new(.54, -5, 1, 0)
        selectedTitle.TextSize = 12
        selectedInfo.TextSize = 11
        selectedDistance.TextSize = 10
    else
        local split = if short then .51 else .65
        mapRegion.Position = UDim2.fromScale(0, 0)
        mapRegion.Size = UDim2.new(split, -10, 1, 0)
        sidebar.Position = UDim2.new(split, 2, 0, 0)
        sidebar.Size = UDim2.new(1 - split, -2, 1, 0)
        detail.Position = UDim2.fromScale(0, 0)
        local detailHeight = if short then 140 else 156
        detail.Size = UDim2.new(1, 0, 0, detailHeight)
        list.Position = UDim2.fromOffset(0, detailHeight + 10)
        list.Size = UDim2.new(1, 0, 1, -(detailHeight + 10))
        selectedTitle.TextSize = if short then 12 else 15
        selectedInfo.TextSize = if short then 11 else 12
        selectedDistance.TextSize = if short then 10 else 12
    end
    selectedTitle.Size = UDim2.new(1, 0, 0, if short then 30 else 40)
    selectedInfo.Position = UDim2.fromOffset(0, if short then 34 else 45)
    selectedDistance.Position = UDim2.fromOffset(0, if short then 90 else 106)
end
panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
resize()
refreshFilter()

local elapsed = 0
local function updatePosition()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then
        you.Visible = false
        selectedDistance.Text = "Seu personagem está carregando…"
        return
    end
    local position = root.Position
    local footPosition = position - Vector3.new(0, 3, 0)
    local floor = positionLevel(footPosition.Y, position)
    local inBounds = math.abs(position.X) <= 300 and math.abs(position.Z) <= 300
    you.Position = uv(position.X, position.Z)
    you.Visible = inBounds and (floorIndex == 1 or floorIndex == floor)
    if selected then
        local distance = math.floor((selected.Position - footPosition).Magnitude + .5)
        local suffix = if floor ~= level(selected) then " · outro piso" else ""
        selectedDistance.Text = ("Distância aproximada: %d studs%s"):format(distance, suffix)
    end
end
local function setOpen(open: boolean)
    panel.Visible = open
    shade.Visible = open
    toggle.Visible = not open
    player:SetAttribute("ZO_TacticalMapOpen", open)
    if open then
        elapsed = 0
        updatePosition()
        if UIS.GamepadEnabled then GuiService.SelectedObject = close end
    elseif GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(panel) then
        GuiService.SelectedObject = nil
    end
end

player:GetAttributeChangedSignal("ZO_ShopOpen"):Connect(function()
    if player:GetAttribute("ZO_ShopOpen")==true then setOpen(false) end
end)
toggle.Activated:Connect(function() setOpen(true) end)
close.Activated:Connect(function() setOpen(false) end)
shade.Activated:Connect(function() setOpen(false) end)
CAS:BindActionAtPriority("ZO_ToggleTacticalMap", function(_, state)
    if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
    if state == Enum.UserInputState.Begin then setOpen(not panel.Visible) end
    return Enum.ContextActionResult.Sink
end, false, 2500, Enum.KeyCode.M, Enum.KeyCode.ButtonSelect)
CAS:BindActionAtPriority("ZO_CloseTacticalMap", function(_, state)
    if not panel.Visible then return Enum.ContextActionResult.Pass end
    if state == Enum.UserInputState.Begin then setOpen(false) end
    return Enum.ContextActionResult.Sink
end, false, 2500, Enum.KeyCode.ButtonB)
UIS.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Escape and panel.Visible then setOpen(false) end
end)
GuiService.MenuOpened:Connect(function() if panel.Visible then setOpen(false) end end)
player.CharacterRemoving:Connect(function() setOpen(false) end)
RunService.Heartbeat:Connect(function(dt)
    if not panel.Visible then return end
    elapsed += dt
    if elapsed < .2 then return end
    elapsed = 0
    updatePosition()
end)
player:SetAttribute("ZO_TacticalMapOpen", false)
