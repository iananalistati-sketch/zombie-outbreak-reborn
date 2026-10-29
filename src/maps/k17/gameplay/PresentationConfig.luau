--!strict
-- Presentation only. Damage, ammunition, cadence and spread live in Config.
local defaults=table.freeze({
    HipPose=CFrame.new(.65,-.8,-1.2), AimFov=58,
    SightOffset=CFrame.new(0,.18,2.2), EyeRelief=.65,
    AnimationPrefix="Rifle", FireVolume=1.4, ReloadVolume=1.1,
    SoundDistance=160, RecoilPitch=.65, ViewKick=.09,
})
local overrides={
    Rifle={AimFov=58},
    SMG={AimFov=62,SightOffset=CFrame.new(0,.13,1.65),RecoilPitch=.45},
    Shotgun={AimFov=64,SightOffset=CFrame.new(0,.13,2.6),RecoilPitch=1.4,ViewKick=.19},
    Pistol={AimFov=62,SightOffset=CFrame.new(0,.08,.65),HipPose=CFrame.new(.45,-.65,-1.25),RecoilPitch=.8},
}
local settings={}
for id,override in overrides do
    local config=table.clone(defaults)
    for key,value in override do config[key]=value end
    settings[id]=table.freeze(config)
end
return table.freeze({get=function(id: string) return settings[id] or defaults end})
