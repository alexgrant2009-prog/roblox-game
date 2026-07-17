--!strict
-- MusicController
-- Loops a background track (from SoundConfig.Music) and cross-fades its volume
-- between "shift" and "idle" levels as the game phase changes. Ships disabled
-- (empty id) so there's no broken-asset warning; paste a Creator Store audio id
-- into SoundConfig.Music.id to turn it on.

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("BlackoutBakery")
local SoundConfig = require(Shared.SoundConfig)

local MusicController = {}
local sound: Sound? = nil

function MusicController.init()
	local cfg = SoundConfig.Music
	if not cfg or cfg.id == "" then
		return -- no track configured; stay silent
	end
	sound = Instance.new("Sound")
	sound.Name = "BakeryMusic"
	sound.SoundId = cfg.id
	sound.Looped = true
	sound.Volume = cfg.idleVolume or 0.12
	sound.Parent = SoundService
	sound:Play()
end

-- Fade toward the shift volume when active, idle volume otherwise.
function MusicController.setActive(active: boolean)
	if not sound then
		return
	end
	local cfg = SoundConfig.Music
	local target = active and (cfg.volume or 0.35) or (cfg.idleVolume or 0.12)
	TweenService:Create(sound, TweenInfo.new(1.5), { Volume = target }):Play()
end

return MusicController
