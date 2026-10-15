--!strict
-- Original Luau implementation of the observed classic loop, not a plugin port.
-- Roblox units and initial tuning: these numbers still need engine playtests.
return table.freeze({
    Rifle = table.freeze({
        Magazine = 30, Reserve = 120, FireInterval = 0.105, ReloadSeconds = 2.4,
        Range = 280, Damage = 22, Knockback = 1,
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
