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
function RoleManager:assign(players: { Player })
	local template = roleTemplate(#players)
	self.assignments = {}
	for i, player in ipairs(players) do
		local idx = ((i - 1 + self.rotationOffset) % #template) + 1
		self.assignments[player] = template[idx]
	end
	return self.assignments
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
function RoleManager:reader(): Player?
	return self:playersWithRole(RoleManager.Reader)[1]
end

return RoleManager
