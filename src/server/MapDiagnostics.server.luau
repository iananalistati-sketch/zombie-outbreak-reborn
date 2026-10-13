--!strict
-- Diagnóstico estrutural seguro, sem alterar objetos ou rotas.
local Workspace = game:GetService("Workspace")
local root = Workspace:WaitForChild("ZO_Survival", 15)
if not root then
    warn("[ZO MAP] Nenhum mapa sincronizado; verifique Workspace.ZO_Survival no modo de edição.")
    return
end
local expected = {
    "00_IndustrialSite", "01_SortingHall", "02_SecurityOffices",
    "03_PowerAndMechanical", "04_ControlRoom", "05_DefendableHideouts",
}
local parts = 0
for _, name in ipairs(expected) do
    local sector = root:FindFirstChild(name)
    if not sector then
        warn("[ZO MAP] Setor ausente: " .. name)
    else
        local n = 0
        for _, part in ipairs(sector:GetDescendants()) do
            if part:IsA("BasePart") then n += 1 end
        end
        parts += n
        print(string.format("[ZO MAP] %s: %d peças", name, n))
    end
end
print(string.format("[ZO MAP] Mapa persistente detectado: %d peças (números não comprovam jogabilidade)", parts))
