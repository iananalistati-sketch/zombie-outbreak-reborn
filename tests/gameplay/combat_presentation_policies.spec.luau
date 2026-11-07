local Handling=require('../../src/maps/k17/gameplay/WeaponHandling')
local Impacts=require('../../src/maps/k17/gameplay/ImpactProfiles')
local Stats=require('../../src/maps/k17/gameplay/RoundStats')
local checks=0
local function check(v,label)assert(v,label);checks+=1 end
for _,id in {'Rifle','SMG','Pistol','Shotgun'} do
    for _,p in {0,1} do local r=Handling.reload(id,p);check(r.Y==0 and math.abs(r.Magazine)<1e-6,'reload endpoints return to neutral')end
    for i=0,100 do
        local r=Handling.reload(id,i/100)
        check(math.abs(r.Pitch)<=1 and math.abs(r.Roll)<=1 and r.Magazine>=0 and r.Magazine<=1,'bounded cosmetic pose')
    end
end
check(Handling.reload('Rifle',.45).HideMagazine and not Handling.reload('Shotgun',.45).HideMagazine,'shotgun never uses a detachable-magazine visual')
check(Handling.pump(.16)>.2 and Handling.pump(2)==0,'pump returns after shot cycle')
check(Impacts.get('DiamondPlate')==Impacts.Metal and Impacts.get('WoodPlanks')==Impacts.Wood,'native material names resolve to reviewed profiles')
check(Impacts.get('unknown')==Impacts.Generic and Impacts.get('Flesh')==Impacts.Flesh,'fallback and zombie effects remain distinct')
local budget=Impacts.budget(24)
for i=1,24 do check(budget:admit(0),'bounded FX allowance')end
check(not budget:admit(.9) and budget:admit(1),'FX budget caps bursts and recovers')
local r=Stats.new(1);Stats.shot(r);Stats.hit(r);Stats.hit(r);Stats.damage(r,1);Stats.damage(r,-4)
check(r.Shots==1 and r.Hits==1 and r.Damage==1,'volley accuracy cannot exceed shots and damage ignores negative values')
check(Stats.accuracy(0,0)==0 and Stats.accuracy(3,2)==67,'accuracy projection is bounded and rounded')
check(Stats.best({})==nil,'empty round has no fabricated highlight')
local best=Stats.best({{Id=2,Kills=0,Infections=0,Objectives=3,Damage=0,Survived=true},
    {Id=1,Kills=0,Infections=0,Objectives=0,Damage=0,Survived=false}})
check(best.Id==2,'Escape objectives and actual survival contribute to round highlight')
print(('PASS combat presentation policies: %d checks'):format(checks))
