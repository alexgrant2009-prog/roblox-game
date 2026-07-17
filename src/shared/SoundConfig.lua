--!strict
-- SoundConfig
-- Named sound effects for the whole game, in one place.
--
-- The defaults use Roblox's BUILT-IN `rbxasset://sounds/*` files. Those ship
-- with every client, need no upload or moderation, and just work -- so the game
-- has audio out of the box. To use your own audio, drop a Marketplace asset id
-- ("rbxassetid://<number>") into any `id` below; nothing else changes.
--
--   volume : 0..1-ish
--   speed  : PlaybackSpeed (pitch); 1.0 = normal, >1 higher, <1 lower

-- These four `rbxasset://sounds/*` files are long-shipped Roblox built-ins;
-- variety comes from pitch (`speed`). Swap any `id` for your own audio.
local CLICK = "rbxasset://sounds/button.wav"
local SWITCH = "rbxasset://sounds/switch.wav"
local PING = "rbxasset://sounds/electronicpingshort.wav"
local SPLASH = "rbxasset://sounds/impact_water.mp3"

local SoundConfig = {
	-- Kitchen (played positionally on world parts, server-side)
	AddIngredient = { id = CLICK,  volume = 0.5, speed = 1.2 },
	Scrap         = { id = SPLASH, volume = 0.5, speed = 1.1 },
	BakeStart     = { id = SWITCH, volume = 0.7, speed = 0.8 },
	BakeDone      = { id = PING,   volume = 0.7, speed = 1.0 },
	ServePerfect  = { id = PING,   volume = 0.8, speed = 1.5 },
	ServePerfect2 = { id = PING,   volume = 0.8, speed = 2.0 }, -- second note of the success chime
	ServePartial  = { id = CLICK,  volume = 0.7, speed = 1.0 },
	ServeFail     = { id = SPLASH, volume = 0.6, speed = 0.7 },

	-- UI / global (fired to clients, played 2D)
	OrderTimeout  = { id = SPLASH, volume = 0.6, speed = 0.5 },
	Taste         = { id = SWITCH, volume = 0.6, speed = 0.7 },
	CountdownTick = { id = CLICK,  volume = 0.5, speed = 1.0 },
	ShiftStart    = { id = PING,   volume = 0.7, speed = 1.2 },
	ShiftEnd      = { id = PING,   volume = 0.7, speed = 0.8 },
}

-- Looping background music. Roblox's audio-privacy rules mean an arbitrary
-- asset id won't necessarily play inside YOUR game, so this ships disabled.
-- To enable: grab a track from the Creator Store (Toolbox -> Audio, check it's
-- usable in your experience) and paste its id below. `volume` is used during a
-- shift, `idleVolume` in the lobby/summary.
SoundConfig.Music = {
	id = "", -- e.g. "rbxassetid://1234567890"
	volume = 0.35,
	idleVolume = 0.12,
}

return SoundConfig
