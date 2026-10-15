--!strict
-- Initial K-17 survival settings; multiplayer balance still requires Studio tests.
return table.freeze({
    MinimumPlayers = 2,
    Intermission = 12,
    Preparation = 35,
    Duration = 240,
    Results = 7,
    InitialZombieRatio = 1/7,
    MotherZombieTeleport = false,
    RespawnSeconds = 5,
    ZombieHealth = 450,
    HumanHealth = 100,
    ZombieWalkSpeed = 19,
    HumanWalkSpeed = 16,
})
