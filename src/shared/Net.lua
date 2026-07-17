--!strict
-- Net
-- Single source of truth for the RemoteEvents both sides share.
--
-- Direction of each event:
--   Ticket    server -> Reader ONLY   (the current order queue; the secret)
--   TasteHint server -> Taster ONLY   (a fuzzy hint about the in-progress dish)
--   Hud       server -> all           (reputation, timer, score, phase, dish count)
--   Role      server -> each player    (that player's role this round)
--   Announce  server -> all           (toasts + the end-of-round summary)
--   Sfx       server -> all / one     (fire-and-forget 2D UI sound by name)
--   Toss      server -> all           (visual: an ingredient flies bin -> bowl)
--   Ready     client -> server        (lobby ready-up)
--
-- The security boundary is FireClient targeting: Cooks and Tasters are never
-- fired the Ticket event, so the recipe data literally never reaches their
-- clients. This is real, not UI theater.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = {}
Net.FolderName = "BakeryRemotes"
Net.Events = { "Ticket", "TasteHint", "Hud", "Role", "Announce", "Sfx", "Toss", "Ready" }

-- Server: create (or find) the remotes folder and every event under it.
function Net.buildOnServer()
	local folder = ReplicatedStorage:FindFirstChild(Net.FolderName)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = Net.FolderName
		folder.Parent = ReplicatedStorage
	end

	local remotes = {}
	for _, name in ipairs(Net.Events) do
		local ev = folder:FindFirstChild(name)
		if not ev then
			ev = Instance.new("RemoteEvent")
			ev.Name = name
			ev.Parent = folder
		end
		remotes[name] = ev
	end
	return remotes
end

-- Client: wait for the folder + every event, return them keyed by name.
function Net.getOnClient()
	local folder = ReplicatedStorage:WaitForChild(Net.FolderName)
	local remotes = {}
	for _, name in ipairs(Net.Events) do
		remotes[name] = folder:WaitForChild(name)
	end
	return remotes
end

return Net
