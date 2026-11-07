--!nonstrict
-- A retention door closes only in a clear volume; an already closed door stays
-- closed until the hold ends. Merely touching it cannot reopen it.
local Players=game:GetService("Players")
local Gates={}
function Gates.new(map,config)
    local folder=assert(map:FindFirstChild("EscapeHoldGates"),"Portas de retenção ausentes")
    local self={entries={}}
    for _,definition in config.HoldGates do
        local part=assert(folder:FindFirstChild(definition.Name),definition.Name.." ausente")
        table.insert(self.entries,{part=part,stage=definition.Stage,closed=false})
    end
    local function set(entry,closed)
        local part=entry.part
        entry.closed=closed;part.CanCollide=closed;part.CanQuery=closed
        part.Transparency=if closed then .12 else 1;part.CastShadow=closed
        for _,child in part:GetChildren() do if child:IsA("SurfaceGui") then child.Enabled=closed end end
        part:SetAttribute("ZO_GateStatus",if closed then "Closed" else "Open")
    end
    function self:update(stage,status)
        local result="Open"
        for _,entry in self.entries do
            if status~="Holding" or entry.stage~=stage then set(entry,false);continue end
            if entry.closed then result="Closed";continue end
            local include={}
            for _,player in Players:GetPlayers() do if player.Character then table.insert(include,player.Character) end end
            local props=workspace:FindFirstChild("ZO_Barricades");if props then table.insert(include,props) end
            local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Include
            params.FilterDescendantsInstances=include;params.MaxParts=1
            local occupied=#workspace:GetPartBoundsInBox(entry.part.CFrame,entry.part.Size,params)>0
            if occupied then
                entry.part:SetAttribute("ZO_GateStatus","Blocked");result="Blocked"
            else set(entry,true);result="Closed" end
        end
        return result
    end
    function self:destroy()for _,entry in self.entries do set(entry,false) end end
    self:destroy()
    return self
end
return table.freeze(Gates)
