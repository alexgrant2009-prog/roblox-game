--!strict
-- ClientMain (Client entry point)
-- Boots the three client UIs, routes remote events to them, and does LOCAL
-- role-based prompt gating.
--
-- IMPORTANT: the prompt gating below is UX only. Setting ProximityPrompt.Enabled
-- from a LocalScript changes only THIS client's copy -- it does not replicate,
-- so a Reader visually loses the bin prompts. The real enforcement lives on the
-- server (every station handler re-checks the role), so re-enabling a prompt via
-- exploit gains a cheater nothing.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("BlackoutBakery")
local Net = require(Shared.Net)

local folder = script.Parent
local ClientTicketUI = require(folder.ClientTicketUI)
local ClientTasteUI = require(folder.ClientTasteUI)
local ClientHUD = require(folder.ClientHUD)

local player = Players.LocalPlayer
local Remotes = Net.getOnClient()

local myRole = "Spectator"

-- Build UIs
ClientHUD.init(player, Remotes)
ClientTicketUI.init(player)
ClientTasteUI.init(player)

-- Enable only the prompts tagged for my role; disable the rest (locally).
local function gatePrompt(pp: ProximityPrompt)
	local role = pp:GetAttribute("BakeryRole")
	if role ~= nil then
		pp.Enabled = (role == myRole)
	end
end

local function gateAllPrompts()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("ProximityPrompt") then
			gatePrompt(obj)
		end
	end
end

-- Re-gate prompts that stream in after the kitchen is built.
workspace.DescendantAdded:Connect(function(obj)
	if obj:IsA("ProximityPrompt") then
		gatePrompt(obj)
	end
end)

-- Remote routing --------------------------------------------------------------
Remotes.Role.OnClientEvent:Connect(function(role)
	myRole = role
	ClientHUD.setRole(role)
	ClientTicketUI.clear()
	ClientTasteUI.clear()
	gateAllPrompts()
end)

Remotes.Ticket.OnClientEvent:Connect(function(queue)
	ClientTicketUI.render(queue)
end)

Remotes.TasteHint.OnClientEvent:Connect(function(hint)
	ClientTasteUI.show(hint)
end)

Remotes.Hud.OnClientEvent:Connect(function(data)
	ClientHUD.update(data)
end)

Remotes.Announce.OnClientEvent:Connect(function(msg)
	ClientHUD.announce(msg)
end)

gateAllPrompts()
print("[BlackoutBakery] Client ready.")
