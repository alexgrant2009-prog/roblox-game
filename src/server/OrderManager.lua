--!strict
-- OrderManager (Server)
-- Picks recipes, maintains the order queue, ticks each order's patience timer,
-- and -- critically -- fires the ticket to the READER ONLY.
--
-- The front of the queue is the "now serving" order the Cook is building toward.
-- Serving or a timeout dequeues the front and the next order slides forward.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BlackoutBakery")
local RecipeConfig = require(Shared.RecipeConfig)

local OrderManager = {}
OrderManager.__index = OrderManager

local uidCounter = 0
local function nextId(): number
	uidCounter += 1
	return uidCounter
end

function OrderManager.new(ctx)
	return setmetatable({
		ctx = ctx,
		queue = {},
		spawnCooldown = 0,
	}, OrderManager)
end

function OrderManager:reset()
	self.queue = {}
	self.spawnCooldown = 2
end

function OrderManager:front()
	return self.queue[1]
end

function OrderManager:frontRecipe()
	local f = self.queue[1]
	return f and f.recipe or nil
end

function OrderManager:removeFront()
	table.remove(self.queue, 1)
end

local function difficultyTier(ctx, frac: number): number
	local tier = 1
	for _, step in ipairs(ctx.Config.DifficultyRamp) do
		if frac >= step.at then
			tier = step.tier
		end
	end
	return tier
end

local function patienceFor(ctx, frac: number): number
	local base, floor = ctx.Config.BasePatience, ctx.Config.MinPatience
	return base + (floor - base) * math.clamp(frac, 0, 1)
end

function OrderManager:spawnOne(frac: number)
	local pool = RecipeConfig.getByMaxDifficulty(difficultyTier(self.ctx, frac))
	local recipe = pool[math.random(1, #pool)]
	local patience = patienceFor(self.ctx, frac)
	table.insert(self.queue, {
		id = nextId(),
		recipe = recipe,
		patience = patience,
		patienceMax = patience,
	})
end

-- What the Reader's client renders. Recipe ids only -- the client looks up the
-- (shared, non-secret) RecipeConfig to draw names + ingredient lists.
function OrderManager:snapshot()
	local out = {}
	for _, o in ipairs(self.queue) do
		table.insert(out, {
			recipeId = o.recipe.id,
			patience = math.max(0, math.floor(o.patience)),
			patienceMax = math.floor(o.patienceMax),
		})
	end
	return out
end

-- Fire the queue at the Reader ONLY. No other client is ever a recipient.
function OrderManager:refreshTicket()
	local reader = self.ctx.Roles:reader()
	if reader then
		self.ctx.Remotes.Ticket:FireClient(reader, self:snapshot())
	end
end

-- dt seconds elapsed; frac is progress through the shift in [0, 1].
function OrderManager:update(dt: number, frac: number)
	-- Patience countdown; expired orders cost reputation.
	for i = #self.queue, 1, -1 do
		local o = self.queue[i]
		o.patience -= dt
		if o.patience <= 0 then
			table.remove(self.queue, i)
			self.ctx.sfxAll("OrderTimeout")
			self.ctx.loseRep(self.ctx.Config.RepLossMissed,
				("The %s order timed out."):format(o.recipe.name))
		end
	end

	-- Keep the queue populated.
	self.spawnCooldown -= dt
	local interval = 11 - 4 * math.clamp(frac, 0, 1) -- 11s early -> 7s late
	if #self.queue == 0 then
		self:spawnOne(frac)
		self.spawnCooldown = interval
	elseif self.spawnCooldown <= 0 and #self.queue < self.ctx.Config.MaxActiveOrders then
		self:spawnOne(frac)
		self.spawnCooldown = interval
	end

	self:refreshTicket()
end

return OrderManager
