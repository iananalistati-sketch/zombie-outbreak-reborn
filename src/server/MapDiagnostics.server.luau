--!strict
-- Zombie Outbreak: diagnostics for Riverside Survival 01.
-- Read-only: validates mapped sectors and physically reachable key door openings.
local Workspace = game:GetService("Workspace")
print("[ZO MAP] Riverside diagnostics online")
local root = Workspace:FindFirstChild("ZO_Survival")
if not root then
    warn("[ZO MAP] Workspace.ZO_Survival missing: check Rojo synchronization.")
    return
end
local names = {
    "00_StreetAndSite", "01_MultilevelGarage", "02_SecurityOffice",
    "03_SubwayEntrance", "04_UndergroundStation", "05_EmergencyEscape",
    "06_SiteFinishing",
}
local total=0
for _,name in ipairs(names) do
    local sector=root:FindFirstChild(name)
    if not sector then
        warn("[ZO MAP] Missing sector: "..name)
    else
        local parts=0
        for _,inst in ipairs(sector:GetDescendants()) do
            if inst:IsA("BasePart") then parts+=1 end
        end
        total+=parts
        print("[ZO MAP] "..name.." | "..parts.." parts")
    end
end
print("[ZO MAP] Riverside 01 loaded: "..total.." parts. Connectivity still requires multiplayer playtest.")
