--!strict
-- Server-owned magazine/reload state. Time is injected to test actual transitions.
local WeaponState={}
WeaponState.__index=WeaponState
function WeaponState.new(config)
    return setmetatable({config=config,ammo=config.Magazine,reserve=config.Reserve,
        reloadEnds=0,nextShot=-math.huge},WeaponState)
end
function WeaponState:cancelReload(): boolean
    local wasReloading=self.reloadEnds>0
    self.reloadEnds=0
    return wasReloading
end
function WeaponState:advance(now: number): boolean
    if self.reloadEnds==0 or now<self.reloadEnds then return false end
    self.reloadEnds=0
    local amount=math.min(self.config.Magazine-self.ammo,self.reserve)
    self.ammo+=amount;self.reserve-=amount
    return true
end
function WeaponState:reload(now: number): boolean
    if self.reloadEnds>0 or self.ammo>=self.config.Magazine or self.reserve<=0 then return false end
    self.reloadEnds=now+self.config.ReloadSeconds
    return true
end
function WeaponState:fire(now: number): (boolean,string)
    if self.reloadEnds>0 then return false,"Reloading" end
    if now<self.nextShot then return false,"Cooldown" end
    if self.ammo<=0 then return false,"Empty" end
    self.ammo-=1;self.nextShot=now+self.config.FireInterval
    return true,""
end
return WeaponState
