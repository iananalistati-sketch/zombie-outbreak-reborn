--!strict
return table.freeze({
    MinPlayers = 2,
    IntermissionSeconds = 5,
    RoundSeconds = 240,
    InitialZombieRatio = 1/7,
    Survival = table.freeze({ Enabled = true }),
    Escape = table.freeze({ Enabled = false }),
})
