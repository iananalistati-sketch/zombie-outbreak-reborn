--!strict
-- A server-owned warm-up for an otherwise empty server; never counts as ranked.
return table.freeze({
    Mode="Escape",
    Enabled=true, IntroSeconds=5, BetweenWaves=4, ResultSeconds=6, WaveSeconds=90,
    MaxAlive=3, SpawnInterval=2, SpawnProtection=5, AttackRange=3.5,
    AttackDamage=20, AttackCooldown=1, PathInterval=1.5,
    Waves=table.freeze({
        table.freeze({Count=3,Health=130,Speed=8}),
        table.freeze({Count=4,Health=170,Speed=10}),
        table.freeze({Count=5,Health=220,Speed=12}),
    }),
    Escape=table.freeze({
        MaxAlive=4,SpawnInterval=3,MinDistance=28,MaxDistance=95,RetireDistance=160,
        Waves=table.freeze({
            table.freeze({Health=170,Speed=13}),
            table.freeze({Health=220,Speed=16}),
            table.freeze({Health=260,Speed=18}),
        }),
    }),
})
