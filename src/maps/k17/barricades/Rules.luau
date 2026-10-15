--!strict
-- Pure placement policy. Collision, support, line of sight and ownership are server checks.
local Rules = {}

function Rules.phase(state: string?, studio: boolean, practice: boolean, players: number): string?
    if studio and practice and players==1 and state=="Waiting" then return "Active" end
    return state
end

function Rules.finite(value: any): boolean
    return type(value)=="number" and value==value and math.abs(value)<1e6
end

function Rules.footprint(width: number, depth: number, quarter: number): (number, number)
    if quarter%2==0 then return width, depth end
    return depth, width
end

function Rules.candidate(zone, kind, x: any, z: any, quarter: any, rootX: number, rootY: number, rootZ: number, range: number): (boolean, string)
    if not Rules.finite(x) or not Rules.finite(z) or not Rules.finite(quarter) then
        return false, "Posição inválida."
    end
    if quarter%1~=0 or quarter<0 or quarter>3 then return false, "Rotação inválida." end
    local width, depth = Rules.footprint(kind.Width, kind.Depth, quarter)
    if x-width/2<zone.MinX or x+width/2>zone.MaxX or z-depth/2<zone.MinZ or z+depth/2>zone.MaxZ then
        return false, "Mantenha o objeto no estoque."
    end
    if math.abs(rootY-(zone.Floor+3))>4 then return false, "Volte ao térreo do estoque." end
    if (x-rootX)^2+(z-rootZ)^2>range^2 then return false, "Chegue mais perto da posição."
    end
    return true, ""
end

function Rules.canBuild(role: string?, state: string?, alive: boolean): boolean
    return alive and role=="Humans" and (state=="Preparation" or state=="Active")
end

function Rules.canAttack(role: string?, state: string?, alive: boolean): boolean
    return alive and role=="Zombies" and state=="Active"
end

return table.freeze(Rules)
