--!strict
-- Original Luau implementation of the observed classic loop, not a plugin port.
-- Roblox units and initial tuning: these numbers still need engine playtests.
local Weapons = table.freeze({
    Rifle = table.freeze({
        Id="Rifle", Label="Carabina", Slot="Primary", Price=1500,
        Magazine=30, Reserve=120, FireInterval=.105, ReloadSeconds=2.4,
        Range=280, Damage=22, Knockback=1, PropScale=1,
        Spread=.5, MoveSpread=1.3, Recoil=1, Automatic=true, Pellets=1,
        Color=table.freeze({79,158,204}),
        Description="Precisão e cadência equilibradas para segurar corredores.",
    }),
    SMG = table.freeze({
        Id="SMG", Label="Submetralhadora", Slot="Primary", Price=1000,
        Magazine=32, Reserve=160, FireInterval=.075, ReloadSeconds=2,
        Range=200, Damage=14, Knockback=.75, PropScale=.7,
        Spread=.9, MoveSpread=1.6, Recoil=.65, Automatic=true, Pellets=1,
        Color=table.freeze({102,195,151}),
        Description="Rajadas rápidas e recarga curta; melhor a curta distância.",
    }),
    Shotgun = table.freeze({
        Id="Shotgun", Label="Escopeta", Slot="Primary", Price=2200,
        Magazine=8, Reserve=48, FireInterval=.85, ReloadSeconds=2.9,
        Range=140, Damage=10, Knockback=1.25, PropScale=1.6,
        Spread=4, MoveSpread=5, Recoil=2, Automatic=false, Pellets=7,
        Color=table.freeze({221,158,78}),
        Description="Sete projéteis por disparo para conter entradas próximas.",
    }),
    LMG = table.freeze({
        Id="LMG", Label="Metralhadora", Slot="Primary", Price=3200,
        Magazine=80, Reserve=240, FireInterval=.11, ReloadSeconds=4.8,
        Range=260, Damage=20, Knockback=.9, PropScale=.9,
        Spread=1.2, MoveSpread=2, Recoil=1.2, Automatic=true, Pellets=1,
        Color=table.freeze({193,108,96}),
        Description="Muito fôlego de defesa; exige cobertura na recarga longa.",
    }),
    Pistol = table.freeze({
        Id="Pistol", Label="Pistola", Slot="Secondary", Price=0,
        Magazine=12, Reserve=72, FireInterval=.23, ReloadSeconds=1.6,
        Range=180, Damage=18, Knockback=.75, PropScale=.6,
        Spread=.5, MoveSpread=1.2, Recoil=.8, Automatic=false, Pellets=1,
        Color=table.freeze({169,180,197}),
        Description="Arma secundária para emergências durante a recarga.",
    }),
})

return table.freeze({
    Weapons=Weapons,
    WeaponOrder=table.freeze({"Rifle", "SMG", "Shotgun", "LMG", "Pistol"}),
    Rifle=Weapons.Rifle, -- Compatibility for the original rifle state/controller.
    EquipSeconds=.25,
    Economy=table.freeze({
        StartingCredits=3500, MaxCredits=12000, RoundIncome=500,
        KillReward=350, InfectionReward=200, SurvivalReward=800, AmmoPrice=180,
    }),
    Containment=table.freeze({
        HorizontalCap=48, UpwardCap=10, TagSeconds=.18, TagWalkScale=.55,
    }),
    Melee = table.freeze({Range = 6, Cooldown = 0.7}),
    Hitgroups = table.freeze({
        Head = table.freeze({Damage=2, Knockback=1.2}),
        Body = table.freeze({Damage=1, Knockback=1}),
        Arm = table.freeze({Damage=.85, Knockback=.9}),
        Leg = table.freeze({Damage=.75, Knockback=.85}),
    }),
    KnockbackPerDamage = 1.25,
    ZombieClassKnockback = 1,
    AirKnockback = .65,
    MaxVelocityChange = 60,
    RequestInterval = .035,
    EffectDistance = 160,
})
