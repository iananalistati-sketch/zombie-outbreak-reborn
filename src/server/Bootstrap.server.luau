--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
print("[Zombie Outbreak] Server bootstrap OK | Minimum players:", config.MinPlayers)
