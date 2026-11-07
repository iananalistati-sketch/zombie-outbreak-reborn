--!strict
-- Cosmetic curves only. Reload time/ammunition remain server-owned.
local Handling={}
local function smooth(a: number,b: number,t: number): number
    local x=math.clamp((t-a)/(b-a),0,1);return x*x*(3-2*x)
end
function Handling.reload(id: string,progress: number): any
    local p=if progress==progress then math.clamp(progress,0,1) else 0
    local weight=smooth(0,.14,p)*(1-smooth(.82,1,p))
    local shotgun=id=="Shotgun"
    local pitch,roll,yaw=-.24,-.46,.16
    if id=="Pistol" then pitch=.18;roll=-.55;yaw=-.12
    elseif shotgun then pitch=-.18;roll=.6;yaw=-.22
    elseif id=="SMG" then pitch=-.26;roll=-.35;yaw=.12 end
    local mag=(smooth(.12,.32,p)-smooth(.58,.82,p))*(if id=="Pistol" then .48 else .8)
    local phase=if p>=1 then "PRONTO" elseif p<.14 then "PREPARANDO"
        elseif shotgun and p<.82 then "ABASTECENDO" elseif p<.42 then "RETIRANDO CARREGADOR"
        elseif p<.78 then "INSERINDO CARREGADOR" else "FERROLHO"
    local pump=if shotgun and p>=.82 and p<=.98 then math.sin((p-.82)/.16*math.pi)*.18 else 0
    return {X=.05*weight,Y=-.16*weight,Z=.12*weight,Pitch=pitch*weight,Yaw=yaw*weight,Roll=roll*weight,
        Magazine=if shotgun then 0 else mag,HideMagazine=not shotgun and p>.34 and p<.56,Pump=pump,Phase=phase}
end
function Handling.pump(age: number): number
    return if age>=0 and age<.32 then math.sin(age/.32*math.pi)*.22 else 0
end
return table.freeze(Handling)
