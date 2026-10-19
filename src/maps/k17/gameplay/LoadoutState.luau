--!strict
-- Server-owned inventory and economy. No Instances or client-supplied prices.
local WeaponState
if script then
    WeaponState=require(script.Parent.WeaponState)
else
    WeaponState=require("./WeaponState")
end

local LoadoutState={}
LoadoutState.__index=LoadoutState

local function finite(value): boolean
    return type(value)=="number" and value==value and math.abs(value)<math.huge
end

local function shopAllowed(role,phase,alive): (boolean,string)
    if alive~=true then return false,"NotAlive" end
    if role~="Humans" then return false,"HumansOnly" end
    if phase~="Preparation" then return false,"PreparationOnly" end
    return true,""
end

function LoadoutState.new(config)
    local self=setmetatable({
        config=config, credits=config.Economy.StartingCredits,
        primary="Rifle", secondary="Pistol", equipped="Rifle", states={},
        roundId=nil, equipReadyAt=0, _seenRounds={},
    },LoadoutState)
    self:resetWeapons()
    return self
end

function LoadoutState:current()
    return self.config.Weapons[self.equipped],self.states[self.equipped]
end

function LoadoutState:cancelReloads()
    for _,state in self.states do state:cancelReload() end
end

function LoadoutState:resetWeapons()
    self:cancelReloads()
    self.primary="Rifle";self.secondary="Pistol";self.equipped="Rifle"
    self.states={
        Rifle=WeaponState.new(self.config.Weapons.Rifle),
        Pistol=WeaponState.new(self.config.Weapons.Pistol),
    }
    self.equipReadyAt=0
end

function LoadoutState:equip(idOrSlot,now): (boolean,string)
    if not finite(now) then return false,"InvalidTime" end
    local id=idOrSlot
    if idOrSlot=="Primary" then id=self.primary
    elseif idOrSlot=="Secondary" then id=self.secondary end
    if type(id)~="string" or not self.config.Weapons[id] then return false,"UnknownWeapon" end
    if not self.states[id] then return false,"NotOwned" end
    if id==self.equipped then return false,"AlreadyEquipped" end
    self:cancelReloads()
    self.equipped=id
    self.equipReadyAt=now+(self.config.EquipSeconds or .25)
    return true,""
end

function LoadoutState:buy(id,role,phase,alive,now): (boolean,string)
    local allowed,reason=shopAllowed(role,phase,alive)
    if not allowed then return false,reason end
    if not finite(now) then return false,"InvalidTime" end
    local weapon=if type(id)=="string" then self.config.Weapons[id] else nil
    if not weapon then return false,"UnknownWeapon" end
    if self.states[id] then return false,"AlreadyOwned" end
    if weapon.Slot~="Primary" then return false,"InvalidWeapon" end
    if self.credits<weapon.Price then return false,"InsufficientCredits" end
    -- Commit only after every guard. Rebuying cannot refill a magazine for free.
    self:cancelReloads()
    self.credits-=weapon.Price
    self.states[self.primary]=nil
    self.primary=id
    self.states[id]=WeaponState.new(weapon)
    self.equipped=id
    self.equipReadyAt=now+(self.config.EquipSeconds or .25)
    return true,""
end

function LoadoutState:buyAmmo(role,phase,alive): (boolean,string)
    local allowed,reason=shopAllowed(role,phase,alive)
    if not allowed then return false,reason end
    local depleted=false
    for _,state in self.states do
        if state.reserve<state.config.Reserve then depleted=true;break end
    end
    if not depleted then return false,"AmmoFull" end
    local price=self.config.Economy.AmmoPrice
    if self.credits<price then return false,"InsufficientCredits" end
    self.credits-=price
    for _,state in self.states do state.reserve=state.config.Reserve end
    return true,""
end

function LoadoutState:award(amount): number
    if not finite(amount) or amount<=0 then return 0 end
    local delta=math.min(math.floor(amount),math.max(0,self.config.Economy.MaxCredits-self.credits))
    self.credits+=delta
    return delta
end

function LoadoutState:beginRound(roundId): boolean
    if not ((type(roundId)=="string" and #roundId>0) or finite(roundId)) then return false end
    if self._seenRounds[roundId] then return false end
    self._seenRounds[roundId]=true
    self.roundId=roundId
    self:resetWeapons()
    self:award(self.config.Economy.RoundIncome)
    return true
end

return LoadoutState
