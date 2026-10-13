--!strict
-- Zombie Outbreak Reborn | Diagnóstico imediato de sincronização do mapa
-- Somente leitura. Nenhum objeto é alterado.
local Workspace = game:GetService("Workspace")
print("[ZO MAP CHECK v2] Diagnostic script loaded")

local root = Workspace:FindFirstChild("ZO_Survival")
if not root then
    warn("[ZO MAP CHECK v2] Workspace.ZO_Survival ausente. Confira GitHub Desktop Pull origin, src/maps e Rojo Output.")
    return
end

print("[ZO MAP CHECK v2] ZO_Survival presente como "..root.ClassName)
local expected = {
    "00_IndustrialSite",
    "01_SortingHall",
    "02_SecurityOffices",
    "03_PowerAndMechanical",
    "04_ControlRoom",
    "05_DefendableHideouts",
}
local total=0
local missing=0
for _,name in ipairs(expected) do
    local sector=root:FindFirstChild(name)
    if not sector then
        warn("[ZO MAP CHECK v2] SETOR AUSENTE: "..name)
        missing += 1
    else
        local parts=0
        for _,node in ipairs(sector:GetDescendants()) do
            if node:IsA("BasePart") then parts+=1 end
        end
        total += parts
        print("[ZO MAP CHECK v2] "..name.." | "..parts.." pecas")
    end
end
if missing > 0 or total == 0 then
    warn(string.format("[ZO MAP CHECK v2] Mapa incompleto: %d setores ausentes, %d pecas",missing,total))
else
    print(string.format("[ZO MAP CHECK v2] Geometria detectada: %d pecas. Colisoes e jogabilidade ainda precisam de teste.",total))
end
