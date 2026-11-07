--!strict
-- Recolors the reviewed kit's particle texture; no extra asset IDs or damage.
local metal={Metal=true,CorrodedMetal=true,DiamondPlate=true,Foil=true}
local wood={Wood=true,WoodPlanks=true}
local glass={Glass=true,Ice=true}
local stone={Concrete=true,Brick=true,Slate=true,Asphalt=true,Rock=true,Pavement=true,Cobblestone=true,Granite=true}
local data={
    Metal={Color={249,201,112},Count=6,Speed=11,Life=.16,Size=.035,Glow=.7},
    Wood={Color={168,131,87},Count=5,Speed=5,Life=.32,Size=.08,Glow=0},
    Glass={Color={194,223,225},Count=4,Speed=9,Life=.24,Size=.045,Glow=.15},
    Stone={Color={157,155,142},Count=5,Speed=4,Life=.36,Size=.11,Glow=0},
    Flesh={Color={114,144,99},Count=4,Speed=4,Life=.22,Size=.08,Glow=0},
    Generic={Color={185,183,166},Count=4,Speed=5,Life=.28,Size=.07,Glow=0},
}
for _,profile in data do table.freeze(profile.Color);table.freeze(profile) end
function data.get(material: string?): any
    local kind=if material=="Flesh" then "Flesh" elseif metal[material] then "Metal" elseif wood[material] then "Wood"
        elseif glass[material] then "Glass" elseif stone[material] then "Stone" else "Generic"
    return data[kind]
end
function data.budget(limit: number)
    local self={deadline=0,count=0}
    function self:admit(now: number): boolean
        if now>=self.deadline then self.deadline=now+1;self.count=0 end
        if self.count>=limit then return false end
        self.count+=1;return true
    end
    return self
end
return table.freeze(data)
