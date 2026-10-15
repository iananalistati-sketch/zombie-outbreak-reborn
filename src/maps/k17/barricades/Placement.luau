--!strict
-- Server and local preview use the same world queries. Server result is authoritative.
local Placement = {}

function Placement.closest(hull: BasePart, point: Vector3): Vector3
    local p = hull.CFrame:PointToObjectSpace(point)
    local half = hull.Size/2
    return hull.CFrame:PointToWorldSpace(Vector3.new(
        math.clamp(p.X,-half.X,half.X), math.clamp(p.Y,-half.Y,half.Y), math.clamp(p.Z,-half.Z,half.Z)))
end

function Placement.clear(model: Model, cf: CFrame, size: Vector3, map: Instance): (boolean, string)
    -- Query the full solid hull, including other props and character body parts.
    -- Decorations with CanCollide=false do not block placement; characters do.
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {model}
    for _, part in workspace:GetPartBoundsInBox(cf, size-Vector3.new(.04,.04,.04), params) do
        local ancestor = part:FindFirstAncestorOfClass("Model")
        if part.CanCollide or (ancestor and ancestor:FindFirstChildOfClass("Humanoid")) then
            return false, "Espaço ocupado por parede, objeto ou jogador."
        end
    end
    -- Five floor samples, and only the authored map may support a prop. No stacking.
    local floorParams = RaycastParams.new()
    floorParams.FilterType = Enum.RaycastFilterType.Include
    floorParams.FilterDescendantsInstances = {map}
    for _, offset in {Vector3.zero, Vector3.new(-size.X/2+.1,0,-size.Z/2+.1),
        Vector3.new(size.X/2-.1,0,-size.Z/2+.1), Vector3.new(-size.X/2+.1,0,size.Z/2-.1), Vector3.new(size.X/2-.1,0,size.Z/2-.1)} do
        local bottom = cf:PointToWorldSpace(Vector3.new(offset.X,-size.Y/2,offset.Z))
        local hit = workspace:Raycast(bottom+Vector3.new(0,.3,0),Vector3.new(0,-.65,0),floorParams)
        if not hit or hit.Normal.Y<.95 or math.abs(hit.Position.Y-bottom.Y)>.16 then
            return false, "É necessário apoio no piso, sem empilhar."
        end
    end
    return true, ""
end

function Placement.sweep(model: Model, hull: BasePart, target: CFrame, quarter: number, map: Instance, props: Instance): boolean
    -- Conservative volume sweep: rotating uses the full diagonal at both endpoints.
    -- This intentionally rejects tight turns near walls rather than teleporting through them.
    local oldQuarter = model:GetAttribute("ZO_Quarter") or 0
    local rotating = quarter~=oldQuarter
    local radius = math.sqrt(hull.Size.X^2+hull.Size.Z^2)
    local size = if rotating then Vector3.new(radius,hull.Size.Y-.1,radius) else hull.Size-Vector3.new(.08,.1,.08)
    local start = if rotating then CFrame.new(hull.Position) else hull.CFrame
    local delta = target.Position-start.Position
    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Exclude
    overlap.FilterDescendantsInstances = {model}
    overlap.RespectCanCollide = true
    if #workspace:GetPartBoundsInBox(start,size,overlap)>0 then return false end
    local ray = RaycastParams.new()
    ray.FilterType = Enum.RaycastFilterType.Include
    ray.FilterDescendantsInstances = {map,props}
    ray.RespectCanCollide = true
    if delta.Magnitude>.01 and workspace:Blockcast(start,size,delta,ray) then return false end
    if rotating and #workspace:GetPartBoundsInBox(CFrame.new(target.Position),size,overlap)>0 then return false end
    return true
end

return Placement
