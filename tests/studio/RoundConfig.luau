--!strict
-- Only the separate validation place maps this module as Shared.RoundConfig.
local config=table.clone(require(script.Parent.ProductionRoundConfig))
config.Intermission=2
config.Preparation=3
config.Duration=30
config.Results=3
return table.freeze(config)
