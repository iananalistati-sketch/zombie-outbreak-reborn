local State=require('../../src/maps/k17/gameplay/TacticalState')
local Config=require('../../src/maps/k17/gameplay/Config')
local refuges=require('../../src/maps/k17/Refuges')
local checks=0
local function check(value,label)assert(value,label);checks+=1 end
check(State.ratio(250,100)==1 and State.ratio(-3,100)==0 and State.ratio(5,0)==0,'health/progress ratios stay bounded')
check(State.ratio(0/0,100)==0,'NaN cannot break a UI size')
for id,r in refuges do
    local b=r.Bounds;local name,data=State.zone(refuges,(b[1]+b[2])/2,r.Floor+3,(b[3]+b[4])/2)
    check(data~=nil and #name>0,'authored refuge is discoverable on its actual floor: '..id)
end
check(State.zone(refuges,-68,5,-136)=='Administração','initial spawn identifies administration')
local _,data=State.zone({[1]={Bounds={0,10,0,10},Floor=1,Label='lower'},[2]={Bounds={0,10,0,10},Floor=15,Label='upper'}},5,18,5)
check(data.Label=='upper','overlapping floor plans cannot reveal the wrong storey')
local _,nested=State.zone({[1]={Bounds={0,20,0,20},Floor=1,Label='wide'},[2]={Bounds={4,6,4,6},Floor=1,Label='niche'}},5,4,5)
check(nested.Label=='niche','small niche takes priority over containing room')
for _,phase in {'Waiting','Preparation','Active','Training','Results','Intermission'} do
    local human=State.objective(phase,'Humans','Humans','Fighting')
    check(type(human)=='string' and #human>0,'all gameplay phases have an objective')
end
check(State.objective('Active','Humans')~=State.objective('Active','Zombies'),'infection changes the objective')
check(State.report({Kind='Fake',Actor='x'},Config.Weapons)==nil,'unrecognized feed events are rejected')
check(State.report({Kind='Elimination',Weapon='Fake'},Config.Weapons)==nil,'unknown weapon cannot produce an elimination entry')
check(State.report({Kind='Elimination',Actor='Alice',Victim='Bob',Weapon='Rifle',Head=true},Config.Weapons):find('CABEÇA',1,true)~=nil,'headshot confirmation is preserved')
local feed=State.feed(4,6)
for i=1,20 do feed:push(tostring(i),i*.1,false) end
check(#feed.items==4 and feed.items[1].text=='20','burst reports remain bounded and newest first')
feed:expire(7.85);check(#feed.items==2,'entries expire individually')
feed:expire(8.1);check(#feed.items==0,'expired reports are released')
local source={{Id=2,Name='B',Role='Zombies',Kills=10,Infections=2},{Id=1,Name='A',Role='Humans',Kills=1,Infections=0}}
local order=State.order(source)
check(order[1].Id==1 and source[1].Id==2,'scoreboard groups roles without mutating caller data')
print(('PASS tactical presentation policies: %d checks'):format(checks))
