--!strict
-- Run during Play, in the SERVER Command Bar:
-- require(game.ServerStorage.ZO_Validation.K17Audit)()
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
type Route = {name: string, origin: Vector3, target: Vector3}

return function()
    assert(RunService:IsStudio() and RunService:IsRunning(), "Use Studio Play, server context")
    local map = Workspace:FindFirstChild("ZO_K17Foundry")
    assert(map, "K-17 is not loaded")
    local passed, failed = 0, 0
    local function record(ok: boolean, label: string)
        if ok then passed += 1; print("[K17 AUDIT] PASS " .. label)
        else failed += 1; warn("[K17 AUDIT] FAIL " .. label) end
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = {map}
    local spawns = map:FindFirstChild("Spawns")
    assert(spawns, "Spawn markers missing")
    for _, name in {"HumanSpawn", "ZombieSpawn", "LobbySpawn"} do
        local marker = spawns:FindFirstChild(name)
        if marker and marker:IsA("BasePart") then
            local hit = Workspace:Raycast(marker.Position + Vector3.new(0, 3, 0), Vector3.new(0, -8, 0), params)
            record(hit ~= nil and hit.Normal.Y > .9, "floor below " .. name)
        else record(false, "missing " .. name) end
    end
    local defenses = map:FindFirstChild("DefensePoints")
    record(defenses ~= nil and #defenses:GetChildren() == 44, "44 registered defense positions")
    local routes: {Route} = {
        {name="admin west stair", origin=Vector3.new(-132,3,-221), target=Vector3.new(-132,17,-181)},
        {name="admin east stair to roof", origin=Vector3.new(-4,31,-221), target=Vector3.new(-4,45,-181)},
        {name="admin power bridge", origin=Vector3.new(-68,17,-150), target=Vector3.new(144,17,-150)},
        {name="power west stair", origin=Vector3.new(56,3,-221), target=Vector3.new(56,17,-181)},
        {name="power east stair to roof", origin=Vector3.new(232,17,-221), target=Vector3.new(232,31,-181)},
        {name="warehouse west stair", origin=Vector3.new(-248,3,-39), target=Vector3.new(-248,17,1)},
        {name="warehouse east stair to roof", origin=Vector3.new(-186,17,-39), target=Vector3.new(-186,31,1)},
        {name="warehouse foundry bridge", origin=Vector3.new(-217,17,123), target=Vector3.new(-131,17,140)},
        {name="foundry west gallery", origin=Vector3.new(-131,3,92), target=Vector3.new(-131,17,136)},
        {name="foundry east gallery", origin=Vector3.new(113,3,176), target=Vector3.new(113,17,232)},
        {name="foundry west roof", origin=Vector3.new(-156,3,76), target=Vector3.new(-132,31,153)},
        {name="foundry east roof", origin=Vector3.new(160,3,128), target=Vector3.new(116,31,205)},
        {name="tower to fourth floor", origin=Vector3.new(188,31,-7), target=Vector3.new(230,45,58)},
        {name="tower east stair to roof", origin=Vector3.new(232,45,-7), target=Vector3.new(232,59,33)},
        {name="tower west control balcony", origin=Vector3.new(188,45,33), target=Vector3.new(169,45,-39)},
        {name="tower east control balcony", origin=Vector3.new(232,45,33), target=Vector3.new(251,45,-39)},
        {name="gantry west", origin=Vector3.new(-80,3,0), target=Vector3.new(48,17,0)},
        {name="gantry east", origin=Vector3.new(168,3,8), target=Vector3.new(48,17,0)},
        {name="upper container", origin=Vector3.new(-140,3,-82), target=Vector3.new(-80,15,-82)},
        {name="north sewer access", origin=Vector3.new(30,2,-56), target=Vector3.new(0,-22,-120)},
        {name="east sewer access", origin=Vector3.new(140,2,116), target=Vector3.new(140,-22,178)},
        {name="west sewer access", origin=Vector3.new(-266,2,188), target=Vector3.new(-204,-22,178)},
        {name="pump room", origin=Vector3.new(-220,-22,144), target=Vector3.new(0,-22,144)},
        {name="outer sewer circuit", origin=Vector3.new(-220,-22,-212), target=Vector3.new(220,-22,178)},
    }
    for _, test in routes do
        local path = PathfindingService:CreatePath({AgentRadius=1.5, AgentHeight=5.5, AgentCanJump=false, WaypointSpacing=4})
        local ok, message = pcall(function() path:ComputeAsync(test.origin, test.target) end)
        record(ok and path.Status == Enum.PathStatus.Success, test.name)
        if not ok then warn("[K17 AUDIT] " .. tostring(message)) end
        path:Destroy()
    end
    for _, test in {
        {name="admin door open", origin=Vector3.new(-68,5,-120), target=Vector3.new(-68,5,-128), clear=true},
        {name="foundry loading open", origin=Vector3.new(-82,5,64), target=Vector3.new(-82,5,74), clear=true},
        {name="admin wall blocks infection ray", origin=Vector3.new(-82,3,-120), target=Vector3.new(-82,3,-128), clear=false},
    } do
        local hit = Workspace:Raycast(test.origin, test.target-test.origin, params)
        record((hit == nil) == test.clear, test.name)
    end
    -- The monitor glass is above this segment. An opaque slab under it must fail.
    for _,x in {-80,20} do
        for _,z in {112,214} do
            local hit=Workspace:Raycast(Vector3.new(x,28.2,z),Vector3.new(0,2,0),params)
            record(hit==nil,("foundry roof aperture %.0f/%.0f"):format(x,z))
        end
    end
    print(("[K17 AUDIT] COMPLETE: %d passed, %d failed. Walk every stair; inspect both invasion routes and multiplayer separately."):format(passed,failed))
    return {passed=passed, failed=failed}
end
