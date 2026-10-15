--!strict
local Workspace = game:GetService("Workspace")
local map = Workspace:WaitForChild("ZO_K17Foundry", 15)
if not map then
    warn("[K17] Map missing: open the K-17 .rbxl or sync default.project.json")
    return
end
local parts, loose, lights = 0, 0, 0
for _, item in map:GetDescendants() do
    if item:IsA("BasePart") then
        parts += 1
        if not item.Anchored then loose += 1 end
    elseif item:IsA("Light") then
        lights += 1
    end
end
local defenses = map:FindFirstChild("DefensePoints")
print(("[K17] Loaded: %d parts, %d unanchored, %d lights, %d defense markers"):format(parts, loose, lights, if defenses then #defenses:GetChildren() else 0))
if loose > 0 then warn("[K17] Unanchored map geometry requires inspection") end
for _, old in {"ZO_SantaAurora", "ZO_HarborCollision", "HarborLocks_Survival_Visual", "ZO_Survival", "ZO_TestSpawns"} do
    if Workspace:FindFirstChild(old) then
        warn("[K17] Previous scene overlaps the new place: " .. old .. ". Keep a backup and use the supplied K-17 place for validation.")
    end
end
print("[K17] Server Command Bar during Studio Play: require(game.ServerStorage.ZO_Validation.K17Audit)()")
print("[K17] Loaded geometry is not proof of navigation, visual quality, frame rate or multiplayer balance.")
