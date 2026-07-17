--!strict
-- DishState (Server)
-- Tracks the in-progress dish's current ingredients. There is one shared bowl
-- per kitchen; both Cooks (in a 4-player game) add into the same DishState.
--
-- Lives only on the server. Cooks never receive the recipe, and the raw dish
-- contents are only surfaced to players indirectly (a count for the Cook via
-- the HUD, and fuzzy hints for the Taster via TasteService).

local DishState = {}
DishState.__index = DishState

function DishState.new()
	return setmetatable({
		ingredients = {} :: { [string]: number },
		total = 0,
		baked = false,
		baking = false,
		burnt = false,
		bakeElapsed = 0, -- seconds the current dish has spent in the oven
		bakeId = 0, -- bumped whenever a pending bake should be invalidated
	}, DishState)
end

function DishState:add(ingredient: string, amount: number?)
	local n = amount or 1
	self.ingredients[ingredient] = (self.ingredients[ingredient] or 0) + n
	self.total += n
	-- Adding a raw ingredient un-bakes the dish; it needs another trip to the oven.
	self.baked = false
end

function DishState:clear()
	self.ingredients = {}
	self.total = 0
	self.baked = false
	self.baking = false
	self.burnt = false
	self.bakeElapsed = 0
	self.bakeId += 1 -- invalidate any in-flight bake
end

function DishState:isEmpty(): boolean
	return self.total == 0
end

-- Begin a bake. Returns a token; the bake loop keeps running only while this
-- token still matches bakeId, so a scrap/clear (which bumps bakeId) stops it.
function DishState:startBake(): number
	self.baking = true
	self.baked = false
	self.burnt = false
	self.bakeElapsed = 0
	self.bakeId += 1
	return self.bakeId
end

-- Taken out during the ready window -> properly baked.
function DishState:finishBake()
	self.baking = false
	self.baked = true
end

-- Taken out too early -> still raw, back to square one for the oven.
function DishState:cancelBake()
	self.baking = false
	self.baked = false
	self.bakeElapsed = 0
end

-- Left in too long -> burnt and ruined; must be scrapped.
function DishState:burn()
	self.baking = false
	self.baked = false
	self.burnt = true
end

-- A defensive copy of the current contents.
function DishState:snapshot(): { [string]: number }
	local copy = {}
	for k, v in pairs(self.ingredients) do
		copy[k] = v
	end
	return copy
end

return DishState
