--!strict
-- ClientSound
-- Plays named 2D sounds locally (UI feedback). Driven by the Sfx remote and a
-- couple of direct client events (e.g. the taste slurp). World/positional
-- sounds are handled server-side; this is only the flat UI layer.

local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("BlackoutBakery")
local SoundConfig = require(Shared.SoundConfig)

local ClientSound = {}

function ClientSound.play(name: string)
	local cfg = SoundConfig[name]
	if not cfg then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = cfg.id
	s.Volume = cfg.volume or 0.5
	s.PlaybackSpeed = cfg.speed or 1
	s.Parent = SoundService
	s:Play()
	Debris:AddItem(s, 6)
end

return ClientSound
