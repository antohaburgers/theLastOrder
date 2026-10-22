--!strict
-- Prototype configuration; tuning values are placeholders, not final balance.
local Config = {}

Config.HUMANS = "Humans"
Config.MACHINES = "Machines"
Config.TeamColors = {
    Humans = Color3.fromRGB(70, 147, 228),
    Machines = Color3.fromRGB(216, 91, 84),
}
Config.BotsPerTeam = 5 -- First test: 5 vs 5. Increase only after profiling.
Config.MaxBotsPerPlayer = 10 -- Planned final system; not applied in this prototype.
Config.BotHealth = 100
Config.BotWalkSpeed = 10
Config.BotEngageRange = 66
Config.BotFireInterval = 1.35
Config.BotDamage = 12
Config.PlayerFireInterval = 0.38
Config.PlayerDamage = 18
Config.MaxWeaponRange = 125
Config.CaptureRadius = 16
Config.CapturePointsPerSecond = 5
Config.PlayerCaptureWeight = 2.5
Config.BotCaptureWeight = 1
Config.CaptureMaxWeight = 4
Config.ArenaSize = Vector3.new(220, 2, 145)
Config.Center = Vector3.new(0, 1.5, 0)
Config.BasePositions = {
    Humans = Vector3.new(-91, 2.5, 0),
    Machines = Vector3.new(91, 2.5, 0),
}

return Config
