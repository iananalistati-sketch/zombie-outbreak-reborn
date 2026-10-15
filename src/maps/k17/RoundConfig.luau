--!strict
-- Initial K-17 survival settings; multiplayer balance still requires Studio tests.
return table.freeze({
    MinimumPlayers = 2,
    Intermission = 12,
    Preparation = 35,
    Duration = 240,
    Results = 7,
    InfectionDistance = 4.5,
    InfectionPoll = 0.15,
    InitialZombieRatio = 0.2,
    ZombieHealth = 450,
    HumanHealth = 100,
    ZombieWalkSpeed = 19,
    HumanWalkSpeed = 16,
})
