--!strict
-- RecipeConfig
-- Static dish + ingredient definitions.
--
-- This module lives in ReplicatedStorage, so it replicates to every client.
-- That is fine and intentional: the *cookbook* is not the secret. The secret
-- is WHICH recipe the current order is -- and that recipeId is only ever fired
-- to the Reader (see OrderManager). A Cook who dumps this module out of the dev
-- console still has no idea which of these dishes is on the ticket right now.

local RecipeConfig = {}

-- Ingredient catalog.
--   flavor -> drives the fuzzy taste hints (TasteService)
--   color  -> tints the bin the KitchenBuilder spawns
RecipeConfig.Ingredients = {
	Flour    = { display = "Flour",    flavor = "doughy",     icon = "🌾", color = Color3.fromRGB(235, 225, 200) },
	Sugar    = { display = "Sugar",    flavor = "sweet",      icon = "🍬", color = Color3.fromRGB(250, 250, 250) },
	Butter   = { display = "Butter",   flavor = "rich",       icon = "🧈", color = Color3.fromRGB(245, 220, 120) },
	Eggs     = { display = "Eggs",     flavor = "eggy",       icon = "🥚", color = Color3.fromRGB(250, 235, 170) },
	Milk     = { display = "Milk",     flavor = "creamy",     icon = "🥛", color = Color3.fromRGB(240, 240, 245) },
	Cocoa    = { display = "Cocoa",    flavor = "chocolatey", icon = "🍫", color = Color3.fromRGB(90, 55, 40) },
	Berries  = { display = "Berries",  flavor = "fruity",     icon = "🫐", color = Color3.fromRGB(150, 40, 90) },
	Salt     = { display = "Salt",     flavor = "salty",      icon = "🧂", color = Color3.fromRGB(220, 220, 225) },
	Vanilla  = { display = "Vanilla",  flavor = "sweet",      icon = "🌼", color = Color3.fromRGB(215, 180, 140) },
	Cinnamon = { display = "Cinnamon", flavor = "spiced",     icon = "🍂", color = Color3.fromRGB(170, 100, 60) },
}

-- Stable order so the bins spawn in a predictable layout.
RecipeConfig.IngredientOrder = {
	"Flour", "Sugar", "Butter", "Eggs", "Milk",
	"Cocoa", "Berries", "Salt", "Vanilla", "Cinnamon",
}

-- Recipes. `difficulty` gates which recipes can appear as the shift heats up.
RecipeConfig.Recipes = {
	{ id = "sugar_cookie",   name = "Sugar Cookie",      difficulty = 1,
	  ingredients = { Flour = 2, Sugar = 2, Butter = 1, Eggs = 1 } },

	{ id = "vanilla_muffin", name = "Vanilla Muffin",    difficulty = 1,
	  ingredients = { Flour = 2, Sugar = 1, Milk = 1, Eggs = 1, Vanilla = 1 } },

	{ id = "choc_cupcake",   name = "Chocolate Cupcake", difficulty = 2,
	  ingredients = { Flour = 2, Sugar = 2, Cocoa = 2, Butter = 1, Eggs = 1 } },

	{ id = "berry_scone",    name = "Berry Scone",       difficulty = 2,
	  ingredients = { Flour = 3, Sugar = 1, Butter = 2, Berries = 2, Milk = 1 } },

	{ id = "cinnamon_roll",  name = "Cinnamon Roll",     difficulty = 3,
	  ingredients = { Flour = 3, Sugar = 2, Butter = 2, Cinnamon = 2, Milk = 1, Eggs = 1 } },

	{ id = "choc_gateau",    name = "Chocolate Gateau",  difficulty = 3,
	  ingredients = { Flour = 3, Sugar = 3, Cocoa = 3, Butter = 2, Eggs = 2, Milk = 1 } },
}

function RecipeConfig.getById(id: string)
	for _, r in ipairs(RecipeConfig.Recipes) do
		if r.id == id then
			return r
		end
	end
	return nil
end

-- Every recipe at or below the given difficulty tier.
function RecipeConfig.getByMaxDifficulty(tier: number)
	local out = {}
	for _, r in ipairs(RecipeConfig.Recipes) do
		if r.difficulty <= tier then
			table.insert(out, r)
		end
	end
	return out
end

return RecipeConfig
