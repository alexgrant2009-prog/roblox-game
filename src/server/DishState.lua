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
	}, DishState)
end

function DishState:add(ingredient: string, amount: number?)
	local n = amount or 1
	self.ingredients[ingredient] = (self.ingredients[ingredient] or 0) + n
	self.total += n
end

function DishState:clear()
	self.ingredients = {}
	self.total = 0
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
