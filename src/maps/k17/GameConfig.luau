--!strict
return table.freeze({
    MinPlayers = 2,
    IntermissionSeconds = 12,
    RoundSeconds = 240,
    InitialZombieRatio = 0.2,
    Survival = table.freeze({ Enabled = true }),
    Escape = table.freeze({ Enabled = false }),
})
