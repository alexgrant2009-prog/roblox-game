--!strict
-- TasteService (Server)
-- Diffs the in-progress DishState against the target recipe and returns a
-- single FUZZY hint. The hint never states a number or (usually) an exact
-- ingredient -- it points at a flavor direction ("needs to be sweeter",
-- "it's too doughy"). Fuzzy on purpose: funnier, and harder to cheese than an
-- exact "add 1 sugar" diff.
--
-- The result is fired only at the Taster (IngredientStation.handleTaste).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BlackoutBakery")
local RecipeConfig = require(Shared.RecipeConfig)
local DishMath = require(Shared.DishMath)

local TasteService = {}

-- Phrase tables keyed by ingredient flavor.
local tooMuch = {
	sweet      = "Whew -- it's way too sweet.",
	doughy     = "It's gone stodgy. Too much flour.",
	rich       = "Too rich -- ease off the butter.",
	eggy       = "Tastes eggy. That's too many eggs.",
	creamy     = "It's soupy -- too much milk.",
	chocolatey = "It's turned bitter with cocoa.",
	fruity     = "Overpoweringly fruity.",
	salty      = "Yuck -- way too salty.",
	spiced     = "The spice is overwhelming.",
}

local needsMore = {
	sweet      = "It needs to be sweeter.",
	doughy     = "It's too thin -- needs more body.",
	rich       = "A bit lean. Needs more butter.",
	eggy       = "It won't bind -- needs an egg.",
	creamy     = "It's dry. Could use some milk.",
	chocolatey = "It should be more chocolatey.",
	fruity     = "It could use more fruit.",
	salty      = "It's flat -- needs a pinch of salt.",
	spiced     = "It wants more spice.",
}

function TasteService.hintFor(dishSnapshot: { [string]: number }, targetRecipe): string
	if not targetRecipe then
		return "There's no order up to taste against."
	end

	local total = 0
	for _, v in pairs(dishSnapshot) do
		total += v
	end
	if total == 0 then
		return "It's an empty bowl. Get something in there!"
	end

	if DishMath.matchScore(dishSnapshot, targetRecipe.ingredients) >= 1.0 then
		return "Mmm -- that tastes just right. Serve it!"
	end

	-- Pick the single biggest discrepancy.
	local diffs = DishMath.diffs(dishSnapshot, targetRecipe.ingredients)
	local worstIng, worstMag, worstDir = nil, 0, 0
	for ing, d in pairs(diffs) do
		if math.abs(d) > worstMag then
			worstMag = math.abs(d)
			worstIng = ing
			worstDir = d
		end
	end

	if not worstIng then
		return "Something's a little off, but I can't place it."
	end

	local meta = RecipeConfig.Ingredients[worstIng]
	local flavor = (meta and meta.flavor) or "off"
	local display = (meta and meta.display) or worstIng

	if worstDir > 0 then
		return tooMuch[flavor] or ("There's too much " .. display .. ".")
	else
		return needsMore[flavor] or ("It needs more " .. display .. ".")
	end
end

return TasteService
