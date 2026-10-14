--!strict
-- Run in Studio's SERVER Command Bar during Play:
-- require(game.ServerStorage.ZO_Validation.SantaAuroraAudit)()
-- Engine evidence only: never substitutes for walking both stairs or multiplayer tests.
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

return function()
    assert(RunService:IsStudio() and RunService:IsRunning(), "Run this audit during Studio Play, on the server")
    local map = Workspace:FindFirstChild("ZO_SantaAurora")
    assert(map, "Santa Aurora not found in Workspace")
    local passed, failed = 0, 0
    local function result(ok: boolean, label: string)
        if ok then
            passed += 1
            print("[ZO AUDIT] PASS " .. label)
        else
            failed += 1
            warn("[ZO AUDIT] FAIL " .. label)
        end
    end

    local spawns = map:FindFirstChild("Spawns")
    assert(spawns, "Spawn markers missing")
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = {map}
    for _, name in {"HumanSpawn", "ZombieSpawn", "LobbySpawn"} do
        local marker = spawns:FindFirstChild(name)
        if marker and marker:IsA("BasePart") then
            local floor = Workspace:Raycast(marker.Position + Vector3.new(0, 4, 0), Vector3.new(0, -10, 0), params)
            result(floor ~= nil and floor.Normal.Y > .9, "ground below " .. name)
        else
            result(false, "spawn marker " .. name)
        end
    end

    local sightTests: {{name: string, origin: Vector3, target: Vector3, clear: boolean}} = {
        {name = "shop door", origin = Vector3.new(-73, 5, -26), target = Vector3.new(-73, 5, -34), clear = true},
        {name = "shop brick wall", origin = Vector3.new(-81, 5, -26), target = Vector3.new(-81, 5, -34), clear = false},
        {name = "warehouse loading door", origin = Vector3.new(32, 5, 28), target = Vector3.new(32, 5, 38), clear = true},
        {name = "warehouse brick wall", origin = Vector3.new(12, 5, 28), target = Vector3.new(12, 5, 38), clear = false},
    }
    for _, test in sightTests do
        local hit = Workspace:Raycast(test.origin, test.target - test.origin, params)
        result((hit == nil) == test.clear, "line of sight: " .. test.name)
    end

    local routes: {{name: string, origin: Vector3, target: Vector3}} = {
        {name = "shop and rear exit", origin = Vector3.new(-73, 3, -24), target = Vector3.new(-85, 3, -102)},
        {name = "internal office stair", origin = Vector3.new(-39, 3, -34), target = Vector3.new(-39, 18, -74)},
        {name = "external office stair", origin = Vector3.new(-116, 3, -32), target = Vector3.new(-116, 18, -74)},
        {name = "workshop reception to rear", origin = Vector3.new(64, 3, -24), target = Vector3.new(40, 3, -96)},
        {name = "internal mezzanine stair", origin = Vector3.new(83, 3, 47), target = Vector3.new(83, 16, 86)},
        {name = "external mezzanine stair", origin = Vector3.new(-9, 3, 38), target = Vector3.new(-9, 16, 80)},
    }
    for _, route in routes do
        local path = PathfindingService:CreatePath({
            AgentRadius = 1.5,
            AgentHeight = 5.5,
            AgentCanJump = false,
            WaypointSpacing = 3,
        })
        local ok, message = pcall(function()
            path:ComputeAsync(route.origin, route.target)
        end)
        result(ok and path.Status == Enum.PathStatus.Success, "navigation: " .. route.name)
        if not ok then warn("[ZO AUDIT] " .. tostring(message)) end
        path:Destroy()
    end
    print(("[ZO AUDIT] COMPLETE: %d passed, %d failed. Multiplayer and visual inspection remain manual."):format(passed, failed))
    return {passed = passed, failed = failed}
end
