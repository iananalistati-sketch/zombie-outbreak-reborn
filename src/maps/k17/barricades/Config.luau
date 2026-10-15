--!strict
-- Initial tuning, not a measured multiplayer balance. Plain data also runs in Luau CLI.
return table.freeze({
    EnablePlacement = false, -- Legacy preview prototype; not part of the classic profile.
    Zone = table.freeze({MinX=-261.5, MaxX=-218, MinZ=96, MaxZ=145, Floor=1}),
    PickupRange = 9,
    PlacementRange = 9,
    SelectionTimeout = 25,
    RequestInterval = 0.12,
    MeleeRange = 7,
    MeleeCooldown = 0.7,
    MeleeDamage = 45,
    CarrySpeed = 10,
    Kinds = table.freeze({
        Cabinet = table.freeze({Label="Armário metálico", Width=4.8, Height=6.3, Depth=2.2, Health=360}),
        Table = table.freeze({Label="Mesa reforçada tombada", Width=6, Height=3.6, Depth=2.4, Health=225}),
        Crate = table.freeze({Label="Caixa industrial", Width=3.5, Height=3.5, Depth=3.5, Health=180}),
    }),
    Props = table.freeze({
        Cabinet01 = table.freeze({Kind="Cabinet", X=-253, Z=138}),
        Cabinet02 = table.freeze({Kind="Cabinet", X=-245, Z=138}),
        Table01 = table.freeze({Kind="Table", X=-253, Z=119}),
        Crate01 = table.freeze({Kind="Crate", X=-241, Z=132}),
        Crate02 = table.freeze({Kind="Crate", X=-237, Z=138}),
    }),
})
