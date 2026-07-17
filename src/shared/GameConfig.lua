--!strict
-- GameConfig
-- Central tuning knobs for the whole game. Tweak here, no code changes needed.

local GameConfig = {}

-- Lobby / session
GameConfig.MinPlayers       = 1     -- 1 makes solo testing work; use 2 for the real hidden-info game
GameConfig.MaxPlayers       = 4
GameConfig.SoloRoleAll      = true  -- a lone player gets every role so the loop is playable solo
GameConfig.ReadyCountdown   = 5     -- seconds between "all ready" and shift start
GameConfig.RoundsPerSession = 3     -- rounds before returning to the lobby (roles rotate each round)
GameConfig.ReadyTimeout     = 25    -- start anyway after this many seconds if min players present

-- Shift / scoring
GameConfig.ShiftDuration    = 180   -- seconds per round
GameConfig.StartReputation  = 5     -- missed/wrong orders chip this down; 0 ends the shift early
GameConfig.MaxActiveOrders  = 3     -- how deep the order queue can get

-- Order patience (lerps from Base -> Min as the shift progresses)
GameConfig.BasePatience     = 45
GameConfig.MinPatience      = 22

-- Difficulty ramp: as elapsed shift fraction crosses each `at`, the max recipe tier rises.
GameConfig.DifficultyRamp = {
	{ at = 0.00, tier = 1 },
	{ at = 0.34, tier = 2 },
	{ at = 0.67, tier = 3 },
}

-- Reputation & score
GameConfig.RepLossWrong     = 1     -- serving a dish that doesn't match
GameConfig.RepLossMissed    = 1     -- an order times out
GameConfig.ScorePerfect     = 100
GameConfig.ScorePartial     = 40
GameConfig.MatchThreshold   = 1.0   -- >= this similarity counts as a perfect serve
GameConfig.PartialThreshold = 0.75  -- >= this (but < perfect) is a partial serve

-- Day-end star rating (out of 3). Score needed for 1 / 2 / 3 stars; surviving
-- the shift is always worth at least 1, a failed shift is 0.
GameConfig.StarThresholds   = { 150, 350, 600 }

-- Oven bake step (timing window + burn)
GameConfig.RequireBake   = true   -- a dish must be baked before it can be served
GameConfig.BakeReadyTime = 3.5    -- in the oven this long => properly baked (take it out!)
GameConfig.BakeBurnTime  = 7.0    -- left in this long => burnt and ruined (must scrap)
GameConfig.RepLossBurn   = 0      -- reputation lost when a dish burns (0 = punishment is just lost time)

-- Design decision (see README "Things decided"):
-- Soft fail -- the Cook can scrap the bowl and start over. Set false for hard-fail panic.
GameConfig.AllowDiscard     = true

return GameConfig
