--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
ReplicatedStorage:SetAttribute("ZO_Version",config.Version)
print("[Zombie Outbreak] Server bootstrap OK | Minimum players:", config.MinPlayers)
