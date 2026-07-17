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
	self.bakeId += 1 -- invalidate any in-flight bake
end

function DishState:isEmpty(): boolean
	return self.total == 0
end

-- Begin a bake; returns a token the caller must pass back to finishBake so a
-- stale timer (dish scrapped / round ended mid-bake) can't complete.
function DishState:startBake(): number
	self.baking = true
	self.baked = false
	self.bakeId += 1
	return self.bakeId
end

-- Complete a bake only if it's still the one that started. Returns success.
function DishState:finishBake(token: number): boolean
	if self.baking and self.bakeId == token then
		self.baking = false
		self.baked = true
		return true
	end
	return false
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
