local Prediction=require('../../src/maps/k17/gameplay/ShotPrediction')
local checks=0
local function check(v,label)assert(v,label);checks+=1 end
do
    local p=Prediction.new();p:sync('Rifle',2)
    local a,b=p:fire(0),p:fire(.1)
    check(a and b and p:ammo()==0 and not p:fire(.2),'prediction cannot emit more shots than last known clip')
    check(p:ack('Rifle',a,1)and p:ammo()==0,'acknowledged shot is removed without spending newer pending shot twice')
    p:sync('Rifle',1);check(p:ammo()==0,'attributes arriving between acknowledgements cannot refund the pending last bullet')
    check(p:ack('Rifle',b,0)and p:ammo()==0,'last acknowledgement confirms empty magazine')
    p:sync('Rifle',1);check(p:ammo()==0,'unchanged stale attribute cannot undo newer empty snapshot')
    p:sync('Rifle',0);p:sync('Rifle',2);check(p:ammo()==2,'authoritative refill resets prediction')
end
do
    local p=Prediction.new();p:sync('Pistol',1);local a=p:fire(0)
    check(p:ack('Pistol',a,1)and p:ammo()==1,'rejected shot refunds only local presentation')
    check(not p:ack('Pistol',a,0)and p:ammo()==1,'duplicate acknowledgement cannot spend a bullet')
    local b=p:fire(1);check(p:stalled(2.51)and not p:fire(2.51),'unresponsive authority stops new predicted shots')
    p:ack('Pistol',b,0);check(not p:stalled(3),'valid response releases pending wait')
    p:reset('Rifle',30);check(not p:ack('Pistol',b,0)and p:ammo()==30,'late response from old weapon cannot overwrite new clip')
end
do
    local p=Prediction.new();p:sync('SMG',3);local a,b=p:fire(0),p:fire(.1)
    check(p:ack('SMG',b,1)and p:ammo()==1,'newer acknowledgement consumes all earlier pending attempts')
    check(not p:ack('SMG',a,2)and p:ammo()==1,'out-of-order older response cannot restore spent ammunition')
    local c=p:fire(.2);p:reset('SMG',32)
    check(not p:ack('SMG',c,0)and p:ammo()==32,'round/practice reset rejects old attempt even with same weapon')
    check(p:fire(.3)>c,'attempt IDs remain unique across resets')
end
print(('PASS cosmetic shot prediction: %d checks; no inventory authority'):format(checks))
