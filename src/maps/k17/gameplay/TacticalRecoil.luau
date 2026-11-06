--!strict
-- Separate camera up/side recoil adapted from CIA-SAC-ACS Recoil.lua,
-- commit 678d94f; Apache-2.0 notices/source in third_party/tactical-fps-sources/acs.
-- K-17 replaces the dependency graph/random calls with per-weapon deterministic
-- tuning below. No Evostrike GPL spray tables or parser are incorporated.
local Recoil={}
Recoil.__index=Recoil
local profiles=table.freeze({
    Rifle={reset=.32,side=.4,steps={0,.12,.22,.38,.55,.8,1,.7,.25,-.2,-.6,-1,-.75,-.35,.15,.5,.85}},
    SMG={reset=.3,side=.27,steps={0,-.2,-.45,-.7,-.4,.05,.4,.75,.9,.4,-.1,-.5}},
    Pistol={reset=.38,side=.16,steps={0,.5,-.5,.3,-.3}},
    Shotgun={reset=1.2,side=.24,steps={0,.65,-.65,.35,-.35}},
})
function Recoil.new()
    return setmetatable({id="",index=0,last=-math.huge},Recoil)
end
function Recoil:reset()
    self.id="";self.index=0;self.last=-math.huge
end
function Recoil:shot(id: string,now: number,up: number,scale: number): (number,number)
    local profile=profiles[id] or profiles.Rifle
    if id~=self.id or now-self.last>profile.reset then self.index=0 end
    self.index+=1;self.id=id;self.last=now
    local index=(self.index-1)%#profile.steps+1
    -- ACS treats camera and gun recoil separately. Our camera receives bounded
    -- pitch/yaw, while TacticalSpring handles only the local gun's displacement.
    -- Same ACS half-range arithmetic (vr /2, signed [-rr,lr] /2), with a
    -- deterministic sample replacing math.random and RAND dependencies.
    local verticalRange=up*2*(1+math.min(self.index-1,12)*.025)
    local vertical=math.clamp((verticalRange/2)*scale,0,4)
    local left,right=profile.side*2,profile.side*2
    local sample=(profile.steps[index]+1)/2
    local horizontal=((-right+(left+right)*sample)/2)*scale
    return vertical,horizontal
end
return table.freeze(Recoil)
