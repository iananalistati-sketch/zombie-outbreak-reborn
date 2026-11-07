--!strict
return table.freeze({
    Version = "0.8.0",
    MinPlayers = 2,
    IntermissionSeconds = 5,
    RoundSeconds = 240,
    InitialZombieRatio = 1/7,
    Survival = table.freeze({ Enabled = true }),
    Escape = table.freeze({ Enabled = true }),
})
