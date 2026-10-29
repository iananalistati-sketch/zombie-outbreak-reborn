-- Stateful purchase/equip/reload flows against the shipped pure server modules.
local Config=require("../../src/maps/k17/gameplay/Config")
local Loadout=require("../../src/maps/k17/gameplay/LoadoutState")
local passed=0
local function check(ok,label) assert(ok,label);passed+=1 end
local function near(a,b) return math.abs(a-b)<.00001 end
local function reject(expected,call,label)
    local ok,reason=call()
    check(not ok and reason==expected,label.." ("..tostring(reason)..")")
end

check(Config.Rifle==Config.Weapons.Rifle,"legacy rifle alias retains the live tuning")
check(#Config.WeaponOrder==4,"four selectable weapons; unmodeled LMG removed")
local ids={}
for _,id in Config.WeaponOrder do
    local weapon=Config.Weapons[id]
    check(weapon.Id==id and not ids[id],"stable unique weapon id")
    ids[id]=true
    check(weapon.Magazine>0 and weapon.Reserve>=weapon.Magazine,"usable magazine and reserve")
    check(weapon.FireInterval>0 and weapon.ReloadSeconds>0 and weapon.Range>0,"valid timings and reach")
    check(weapon.Price>=0 and weapon.PropScale>0 and weapon.Pellets>=1,"valid economy and physical shot")
    check(type(weapon.Automatic)=="boolean" and #weapon.Color==3,"input mode and visual metadata")
end

local l=Loadout.new(Config)
local weapon,rifle=l:current()
check(weapon==Config.Rifle and rifle.ammo==30 and rifle.reserve==120,"free starter rifle with actual magazine state")
check(l.secondary=="Pistol" and l.states.Pistol.ammo==12,"free backup pistol")
check(l.credits==3500 and l.roundId==nil,"new player starting budget")
for i=0,4 do check(rifle:fire(i*.2),"accepted rifle burst consumes its magazine") end
check(rifle.ammo==25 and rifle:reload(1),"reload after burst")
local oldDeadline=rifle.reloadEnds
check(l:equip("Secondary",1.1),"switch to secondary during reload")
local _,pistol=l:current()
check(l.equipped=="Pistol" and near(l.equipReadyAt,1.35),"weapon draw has a server deadline")
check(rifle.reloadEnds==0 and not rifle:advance(oldDeadline+1),"switched-away reload cannot finish offscreen")
check(rifle.ammo==25 and rifle.reserve==120,"cancellation does not invent rifle ammunition")
check(pistol:fire(1.4) and pistol:reload(1.5),"pistol has an independent magazine and reload")
check(l:equip("Primary",1.6),"switch back via primary slot")
check(l.states.Rifle==rifle and rifle.ammo==25 and pistol.reloadEnds==0,"slot switching preserves magazines and cancels every reload")
reject("AlreadyEquipped",function() return l:equip("Rifle",2) end,"duplicate draw rejected")
reject("NotOwned",function() return l:equip("Shotgun",2) end,"cannot equip unpurchased primary")
reject("UnknownWeapon",function() return l:equip({},2) end,"non-string weapon rejected")
local credits=l.credits
reject("AlreadyOwned",function() return l:buy("Rifle","Humans","Preparation",true,2) end,"repeated starter purchase cannot refill")
check(rifle.ammo==25 and l.credits==credits,"rejected repeat leaves ammunition and credits unchanged")

check(rifle:reload(2.1),"reload pending before purchase")
check(l:buy("SMG","Humans","Preparation",true,2.2),"buy new primary during preparation")
check(l.credits==2500 and l.primary=="SMG" and l.equipped=="SMG","purchase atomically spends its server price and equips")
check(not l.states.Rifle and l.states.Pistol==pistol,"old primary removed while secondary state survives")
check(rifle.reloadEnds==0 and near(l.equipReadyAt,2.45),"purchase cancels outgoing reload and delays first shot")
local _,smg=l:current()
check(smg:fire(2.5) and smg.ammo==31,"new primary uses its own state")
reject("AlreadyOwned",function() return l:buy("SMG","Humans","Preparation",true,3) end,"repeated SMG purchase rejected")
check(smg.ammo==31 and l.credits==2500,"repeat buy cannot refill or charge")
l.credits=2000
reject("InsufficientCredits",function() return l:buy("Shotgun","Humans","Preparation",true,3) end,"unaffordable weapon rejected without a partial transaction")
l.credits=2500
check(l.primary=="SMG" and l.states.SMG==smg and l.credits==2500,"failed purchase retains original inventory")
check(l:buy("Shotgun","Humans","Preparation",true,3.1),"another paid primary may replace SMG")
check(l.credits==300 and not l.states.SMG and l.states.Pistol==pistol,"replacement gives no resale refund")

for _,role in {"Zombies","Lobby"} do
    reject("HumansOnly",function() return l:buy("Rifle",role,"Preparation",true,4) end,"nonhuman cannot buy")
    reject("HumansOnly",function() return l:buyAmmo(role,"Preparation",true) end,"nonhuman cannot buy ammunition")
end
for _,phase in {"Waiting","Intermission","Active","Results"} do
    reject("PreparationOnly",function() return l:buy("Rifle","Humans",phase,true,4) end,"shop closed outside preparation")
    reject("PreparationOnly",function() return l:buyAmmo("Humans",phase,true) end,"ammunition shop closed outside preparation")
end
reject("NotAlive",function() return l:buy("Rifle","Humans","Preparation",false,4) end,"dead human cannot buy")
reject("NotAlive",function() return l:buyAmmo("Humans","Preparation",false) end,"dead human cannot buy ammunition")
check(l.primary=="Shotgun" and l.credits==300,"role and phase rejections do not mutate loadout")

-- A purchased ammunition pack fills reserves, never the active magazine.
reject("AmmoFull",function() return l:buyAmmo("Humans","Preparation",true) end,"full reserves cannot consume money")
local shotgun=l.states.Shotgun
check(shotgun:fire(5) and shotgun:reload(5.1),"shotgun reload pending")
shotgun.reserve=40;pistol.reserve=60
local reloadDeadline=shotgun.reloadEnds
check(l:buyAmmo("Humans","Preparation",true),"one ammo purchase replenishes both owned reserves")
check(l.credits==120 and shotgun.reserve==48 and pistol.reserve==72,"one server ammo price covers both slots")
check(shotgun.ammo==7 and shotgun.reloadEnds==reloadDeadline,"buying ammo cannot skip or cancel reload")
check(shotgun:advance(reloadDeadline) and shotgun.ammo==8 and shotgun.reserve==47,"pending reload transfers one round at its original deadline")
reject("InsufficientCredits",function() return l:buyAmmo("Humans","Preparation",true) end,"insufficient funds cannot refill depleted reserve")
check(shotgun.reserve==47 and l.credits==120,"unaffordable ammo purchase does not mutate")

-- Infection/death cancellation and round replay cannot farm inventory or income.
check(shotgun:fire(10) and shotgun:reload(10.1),"another pending reload")
l:cancelReloads()
check(shotgun.reloadEnds==0 and not shotgun:advance(100),"infection cancels delayed reload completion")
check(l:beginRound(1),"first round resets starter equipment")
check(l.roundId==1 and l.credits==620 and l.primary=="Rifle" and l.equipped=="Rifle","round pays one stipend and restores starter weapon")
check(l.states.Rifle.ammo==30 and l.states.Pistol.ammo==12 and l.equipReadyAt==0,"round restores both magazines and clear draw timer")
local current=l.states.Rifle
check(current:fire(101),"spend ammunition in new round")
check(not l:beginRound(1) and l.credits==620 and l.states.Rifle==current and current.ammo==29,"duplicate round signal cannot farm stipend or ammunition")
check(l:beginRound(2) and l.credits==1120,"a new round pays once")
local afterRound=l.states.Rifle
check(not l:beginRound(1) and l.roundId==2 and l.states.Rifle==afterRound and l.credits==1120,"replayed historical id cannot farm money or reset weapons")
l:resetWeapons()
check(l.credits==1120 and l.roundId==2 and l.equipped=="Rifle","manual respawn reset preserves economy and round identity")
check(not l:beginRound(2) and l.credits==1120,"respawn reset does not reopen round income")

for _,bad in {0,-1,0/0,math.huge,-math.huge,"350",{},true} do
    check(l:award(bad)==0 and l.credits==1120,"invalid or nonpositive awards cannot alter credits")
end
check(l:award(350)==350 and l.credits==1470,"kill reward applied once per caller event")
check(l:award(999999)==10530 and l.credits==12000,"rewards clamp at maximum balance")
check(l:award(800)==0 and l.credits==12000,"capped credit balance cannot overflow")
check(l:beginRound(3) and l.credits==12000,"round stipend also observes the economy cap")
check(l:buy("SMG","Humans","Preparation",true,200),"earned credits purchase a primary")
local _,burst=l:current()
for i=0,Config.Weapons.SMG.Magazine-1 do check(burst:fire(201+i*.12),"SMG full magazine burst") end
check(burst.ammo==0 and not burst:fire(220),"SMG obeys magazine limit")
check(l:equip("Pistol",220),"secondary remains available when primary is empty")
check(l.states.SMG==burst and burst.ammo==0,"backup switch cannot refill empty primary")

for _,badTime in {0/0,math.huge,-math.huge,"1",{},true} do
    local budget=l.credits
    reject("InvalidTime",function() return l:equip("Primary",badTime) end,"invalid draw time rejected")
    reject("InvalidTime",function() return l:buy("SMG","Humans","Preparation",true,badTime) end,"invalid purchase time rejected")
    check(not burst:reload(badTime) and not burst:advance(badTime) and not burst:fire(badTime),"invalid clock cannot bypass weapon state")
    check(l.credits==budget and l.primary=="SMG","invalid-time request leaves economy untouched")
end
check(not l:beginRound(nil) and not l:beginRound(0/0),"invalid round identity cannot grant income")
print(("PASS arsenal loadout: %d assertions against actual inventory, economy, reload and weapon-state modules"):format(passed))
