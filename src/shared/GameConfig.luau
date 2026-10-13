--!strict
local GameConfig = {
    MinPlayers = 2,
    IntermissionSeconds = 15,
    RoundSeconds = 240,
    InitialZombieRatio = 0.2,
    Survival = { Enabled = true },
    Escape = { Enabled = true },
}
return table.freeze(GameConfig)
