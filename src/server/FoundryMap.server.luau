--!strict
-- Foundry 01: mapa de Survival em setores construídos, não obstáculos aleatórios.
-- A arte continua provisória: apenas materiais nativos e geometria do Studio.
local Workspace = game:GetService("Workspace")
if Workspace:FindFirstChild("ZO_Foundry01") then return end
local map = Instance.new("Model")
map.Name = "ZO_Foundry01"
map.Parent = Workspace
local function part(name: string, pos: Vector3, size: Vector3, material: Enum.Material, color: Color3, parent: Instance?, collide: boolean?): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Anchored = true
    p.CanCollide = collide ~= false
    p.Material = material
    p.Color = color
    p.Size = size
    p.Position = pos
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent or map
    return p
end
local concrete = Color3.fromRGB(100,106,108)
local iron = Color3.fromRGB(53,65,70)
local pale = Color3.fromRGB(144,151,146)
local hazard = Color3.fromRGB(205,153,52)
local glass = Color3.fromRGB(74,125,139)
local function wall(name: string, x:number,z:number,w:number,h:number,t:number)
    return part(name,Vector3.new(x,h/2,z),Vector3.new(w,h,t),Enum.Material.Concrete,concrete)
end
local function wallX(name:string,x:number,z:number,length:number,h:number,t:number)
    return part(name,Vector3.new(x,h/2,z),Vector3.new(t,h,length),Enum.Material.Concrete,concrete)
end
local function lamp(x:number,y:number,z:number)
    local fixture=part("IndustrialLight",Vector3.new(x,y,z),Vector3.new(6,.5,2),Enum.Material.Metal,pale)
    local light=Instance.new("SurfaceLight")
    light.Face=Enum.NormalId.Bottom
    light.Brightness=3
    light.Range=36
    light.Angle=110
    light.Parent=fixture
end
local function step(x:number,y:number,z:number,w:number,d:number)
    return part("Stair",Vector3.new(x,y,z),Vector3.new(w,2,d),Enum.Material.Metal,iron)
end
local function sign(text:string,x:number,y:number,z:number,rot:number)
    local holder=part("Sign_"..text,Vector3.new(x,y,z),Vector3.new(17,4,.3),Enum.Material.Metal,iron,false)
    holder.CFrame=holder.CFrame*CFrame.Angles(0,math.rad(rot),0)
    local gui=Instance.new("SurfaceGui")
    gui.Face=Enum.NormalId.Front
    gui.CanvasSize=Vector2.new(680,160)
    gui.Parent=holder
    local t=Instance.new("TextLabel")
    t.Size=UDim2.fromScale(1,1)
    t.BackgroundTransparency=1
    t.Text=text
    t.Font=Enum.Font.GothamBold
    t.TextColor3=Color3.fromRGB(238,229,195)
    t.TextScaled=true
    t.Parent=gui
end
-- Planta: pátio frontal (-120 a 120,z -125 a 5), galpão central (z 5 a 135),
-- escritório oeste, manutenção leste, sala de controle no fundo.
part("Foundation",Vector3.new(0,-1,30),Vector3.new(260,2,340),Enum.Material.Concrete,pale)
-- Perímetro sem fechar céu; corredores externos dos dois lados.
wall("NorthFence",0,197,250,25,3)
wall("SouthFence",0,-137,250,25,3)
wallX("WestFence",-128,30,335,25,3)
wallX("EastFence",128,30,335,25,3)
-- Galpão central: aberturas frontais e laterais, sem caixas aleatórias.
wall("FrontWest",-51,9,66,24,3)
wall("FrontEast",51,9,66,24,3)
wall("BackWest",-50,138,65,24,3)
wall("BackEast",50,138,65,24,3)
wallX("WarehouseWest",-85,76,125,24,3)
wallX("WarehouseEast",85,76,125,24,3)
-- Aberturas de 36 studs no acesso frontal e 35 no fundo.
part("WarehouseRoof",Vector3.new(0,25,75),Vector3.new(174,2,137),Enum.Material.Metal,iron)
for _,x in ipairs({-72,72}) do
    for _,z in ipairs({25,125}) do
        part("SteelColumn",Vector3.new(x,12,z),Vector3.new(3,24,3),Enum.Material.Metal,iron)
    end
end
-- Passarela superior contínua + duas escadas de acesso, invasível por zumbis.
part("Catwalk",Vector3.new(0,13,124),Vector3.new(165,2,12),Enum.Material.DiamondPlate,iron)
for _,x in ipairs({-68,68}) do
    for i=1,9 do
        local zi=26+i*9
        step(x,i*1.45,zi,10,10)
    end
end
for _,z in ipairs({119,129}) do
    part("CatwalkRail",Vector3.new(0,17,z),Vector3.new(164,3,1),Enum.Material.Metal,hazard)
end
-- Prateleiras coerentes do almoxarifado: linhas paralelas, corredor no meio.
for _,x in ipairs({-44,-20,20,44}) do
    for _,z in ipairs({42,58,74}) do
        part("StorageRack",Vector3.new(x,4,z),Vector3.new(9,8,5),Enum.Material.Metal,iron)
        part("Pallets",Vector3.new(x,8.3,z),Vector3.new(8,1,4),Enum.Material.WoodPlanks,Color3.fromRGB(98,77,57))
    end
end
-- Escritório: bloco oeste ligado ao galpão pelo corredor lateral.
part("OfficeFloor",Vector3.new(-104,1,78),Vector3.new(34,2,96),Enum.Material.Concrete,pale)
wallX("OfficeOutside",-121,83,102,17,2)
wallX("OfficeInside",-88,90,50,17,2)
for _,z in ipairs({36,70,104}) do
    wall("OfficePartition",-104,z,34,17,2)
end
-- Abertura do corredor interno em z=52..78 (não fecha entrada).
part("OfficeGlazing",Vector3.new(-88,11,52),Vector3.new(1,6,19),Enum.Material.Glass,glass,false).Transparency=.38
-- Sala de manutenção a leste; máquinas alinhadas e rota de flanco.
wallX("MaintenanceOuter",120,85,100,18,2)
wallX("MaintenanceInner",90,97,74,18,2)
wall("MaintenanceBack",105,135,30,18,2)
for _,z in ipairs({54,76,98}) do
    part("Generator",Vector3.new(108,4,z),Vector3.new(13,8,10),Enum.Material.Metal,Color3.fromRGB(65,79,79))
    part("GeneratorPipe",Vector3.new(108,10,z),Vector3.new(3,5,3),Enum.Material.Metal,pale)
end
-- Sala de controle no fundo: duas entradas, cobertura com parede divisória.
wall("ControlRear",0,186,112,20,3)
wallX("ControlLeft",-57,164,47,20,2)
wallX("ControlRight",57,164,47,20,2)
wall("ControlPartition",0,165,33,12,2)
part("ControlDesk",Vector3.new(0,3,177),Vector3.new(32,6,6),Enum.Material.Metal,iron)
-- Esconderijo utilizável: túnel curto de ventilação conectado ao corredor oeste.
-- Duas entradas, nenhuma posição inacessível ou invulnerável.
part("VentFloor",Vector3.new(-106,7,4),Vector3.new(16,1,63),Enum.Material.Metal,iron)
part("VentCeiling",Vector3.new(-106,13,4),Vector3.new(16,1,63),Enum.Material.Metal,iron)
for _,x in ipairs({-114,-98}) do
    part("VentSide",Vector3.new(x,10,4),Vector3.new(1,6,63),Enum.Material.Metal,iron)
end
for i=0,5 do step(-106,1+i, -43+i*5,12,4) end
-- Cobertura funcional no pátio; zonas de aproximação visíveis.
for _,x in ipairs({-72,72}) do
    for _,z in ipairs({-78,-42}) do
        part("LoadingContainer",Vector3.new(x,5,z),Vector3.new(23,10,11),Enum.Material.CorrodedMetal,iron)
    end
end
part("DockPlatform",Vector3.new(0,3,-85),Vector3.new(45,6,26),Enum.Material.Concrete,concrete)
for _,z in ipairs({-30,34,95,155}) do lamp(0,23,z) end
sign("FOUNDRY // STORAGE",0,17,7,0)
sign("CONTROL ROOM",0,17,184,180)
sign("MAINTENANCE",111,14,37,0)
sign("OFFICES",-106,14,25,0)
-- Iluminação visível, sem a falha anterior de cenário preto.
local Lighting=game:GetService("Lighting")
Lighting.ClockTime=14
Lighting.Brightness=2.2
Lighting.Ambient=Color3.fromRGB(110,116,126)
Lighting.OutdoorAmbient=Color3.fromRGB(130,136,142)
print("[Zombie Outbreak] Foundry 01 generated | 260x340 studs | warehouse/offices/maintenance/control/vents")
