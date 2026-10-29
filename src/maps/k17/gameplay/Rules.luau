--!strict
-- Pure policy, executed by the CLI tests and by the game.
local Rules={}
function Rules.finite(value: any): boolean
    return type(value)=="number" and value==value and math.abs(value)<1e6
end
function Rules.direction(x: any,y: any,z: any): boolean
    if not Rules.finite(x) or not Rules.finite(y) or not Rules.finite(z) then return false end
    local squared=x*x+y*y+z*z
    return squared>=.98^2 and squared<=1.02^2
end
function Rules.facing(x: number,z: number,forwardX: number,forwardZ: number): boolean
    local length=math.sqrt(x*x+z*z)
    local forward=math.sqrt(forwardX*forwardX+forwardZ*forwardZ)
    return length<.1 or forward<.1 or (x*forwardX+z*forwardZ)/(length*forward)>=.25
end
function Rules.phase(state: string?,studio: boolean,practice: boolean,players: number): string?
    if studio and practice and players==1 and state=="Waiting" then return "Active" end
    return state
end
function Rules.canFire(role: string?,state: string?,alive: boolean,selecting: boolean): boolean
    return alive and not selecting and role=="Humans" and (state=="Preparation" or state=="Active")
end
function Rules.canMelee(role: string?,state: string?,alive: boolean): boolean
    return alive and role=="Zombies" and state=="Active"
end
function Rules.shotSpread(weapon,moving: boolean,aiming: boolean): number
    local base=if moving then weapon.MoveSpread else weapon.Spread
    local aimed=if moving then weapon.AimMoveSpread else weapon.AimSpread
    return if aiming and Rules.finite(aimed) then math.clamp(aimed,0,base) else base
end
function Rules.hitgroup(partName: string): string
    if partName=="Head" then return "Head" end
    local name=string.lower(partName)
    if string.find(name,"arm") or string.find(name,"hand") then return "Arm" end
    if string.find(name,"leg") or string.find(name,"foot") then return "Leg" end
    return "Body"
end
function Rules.knockback(config,damage: number,weaponScale: number,hitgroupScale: number,classScale: number,airborne: boolean): number
    if not Rules.finite(damage) or damage<=0 then return 0 end
    return math.clamp(damage*config.KnockbackPerDamage*weaponScale*hitgroupScale*classScale
        *(if airborne then config.AirKnockback else 1),0,config.MaxVelocityChange)
end
return table.freeze(Rules)
