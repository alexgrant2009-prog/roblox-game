--!strict
-- RoleManager (Server)
-- Assigns and rotates Reader / Cook / Taster each round so everyone plays all
-- three across a session.
--
-- Player-count templates:
--   2 players -> Reader, Cook
--   3 players -> Reader, Cook, Taster
--   4 players -> Reader, Cook, Taster, Cook   (4th = second Cook; kitchen gets busy)

local RoleManager = {}
RoleManager.__index = RoleManager

RoleManager.Reader = "Reader"
RoleManager.Cook   = "Cook"
RoleManager.Taster = "Taster"
RoleManager.Solo   = "Solo" -- lone player during testing: can do everything

function RoleManager.new()
	return setmetatable({
		assignments = {} :: { [Player]: string },
		rotationOffset = 0,
	}, RoleManager)
end

local function roleTemplate(count: number): { string }
	if count <= 2 then
		return { RoleManager.Reader, RoleManager.Cook }
	elseif count == 3 then
		return { RoleManager.Reader, RoleManager.Cook, RoleManager.Taster }
	else
		return { RoleManager.Reader, RoleManager.Cook, RoleManager.Taster, RoleManager.Cook }
	end
end

-- Assign roles for this round. Uses rotationOffset so roles cycle round to round.
-- If `soloAll` and there's exactly one player, they get the Solo role (all
-- abilities) so the game can be walked through end-to-end while testing.
function RoleManager:assign(players: { Player }, soloAll: boolean?)
	self.assignments = {}
	if soloAll and #players == 1 then
		self.assignments[players[1]] = RoleManager.Solo
		return self.assignments
	end
	local template = roleTemplate(#players)
	for i, player in ipairs(players) do
		local idx = ((i - 1 + self.rotationOffset) % #template) + 1
		self.assignments[player] = template[idx]
	end
	return self.assignments
end

-- True if the player currently holds `role` (Solo counts as every role).
function RoleManager:can(player: Player, role: string): boolean
	local r = self.assignments[player]
	return r == role or r == RoleManager.Solo
end

function RoleManager:rotate()
	self.rotationOffset += 1
end

function RoleManager:reset()
	self.rotationOffset = 0
	self.assignments = {}
end

function RoleManager:getRole(player: Player): string?
	return self.assignments[player]
end

function RoleManager:playersWithRole(role: string): { Player }
	local out = {}
	for player, r in pairs(self.assignments) do
		if r == role and player.Parent then
			table.insert(out, player)
		end
	end
	return out
end

-- The single Reader (the only client the Ticket event is ever fired at).
-- A Solo player counts as the Reader too.
function RoleManager:reader(): Player?
	for player, r in pairs(self.assignments) do
		if (r == RoleManager.Reader or r == RoleManager.Solo) and player.Parent then
			return player
		end
	end
	return nil
end

return RoleManager
