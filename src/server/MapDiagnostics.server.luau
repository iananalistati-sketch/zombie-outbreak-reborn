--!strict
-- Diagnostics never modify the scene or mistake geometry for gameplay approval.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MapConfig"))
local map = Workspace:WaitForChild(Config.ModelName, 15)
if not map then
    warn("[ZO MAP] K-17 missing. Use ABRIR_K17.cmd or open builds/ZombieOutbreakReborn_K17.rbxl.")
    return
end
local parts, unanchored, lights = 0, 0, 0
for _, item in map:GetDescendants() do
    if item:IsA("BasePart") then
        parts += 1
        if not item.Anchored then unanchored += 1 end
    elseif item:IsA("Light") then
        lights += 1
    end
end
print(("[ZO MAP] %s: %d parts, %d lights, %d unanchored."):format(Config.DisplayName, parts, lights, unanchored))
if unanchored > 0 then
    warn("[ZO MAP] Unanchored map geometry detected; inspect before testing.")
end
for _, name in {"ZO_HarborCollision", "HarborLocks_Survival_Visual", "ZO_Survival", "ZO_TestSpawns"} do
    if Workspace:FindFirstChild(name) then
        warn("[ZO MAP] Legacy scene still in Workspace: " .. name .. ". Use the separate K-17 place; see README.")
    end
end
print("[ZO MAP] Studio audit: require(game.ServerStorage.ZO_Validation.K17Audit)() in the SERVER Command Bar during Play.")
print("[ZO MAP] Geometry loaded. Visual quality, movement, combat and multiplayer still need Studio playtests.")
