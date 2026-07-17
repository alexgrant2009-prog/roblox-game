--!strict
-- DishMath
-- Pure helpers for comparing an in-progress dish to a target recipe.
-- Used by SubmitStation (scoring) and TasteService (hints).

local DishMath = {}

type Counts = { [string]: number }

-- Similarity in [0, 1]. 1.0 means the dish exactly matches the target
-- (right ingredients, right quantities, nothing extra).
--
-- score = correct / (totalTarget + extra)
--   correct = units that belong and are present (capped at what's needed)
--   extra   = surplus / wrong units that shouldn't be there
-- Exact match  -> correct == totalTarget, extra == 0 -> 1.0
-- Missing units-> correct < totalTarget            -> < 1.0
-- Wrong units  -> extra > 0                          -> < 1.0
function DishMath.matchScore(dish: Counts, target: Counts): number
	local totalTarget, correct, extra = 0, 0, 0

	for ing, need in pairs(target) do
		totalTarget += need
		local have = dish[ing] or 0
		correct += math.min(have, need)
	end

	for ing, have in pairs(dish) do
		local need = target[ing] or 0
		if have > need then
			extra += (have - need)
		end
	end

	if totalTarget == 0 then
		return 0
	end
	return correct / (totalTarget + extra)
end

-- Signed diffs (dish - target) for every ingredient that appears in either.
-- Positive => too much, negative => not enough.
function DishMath.diffs(dish: Counts, target: Counts): Counts
	local out: Counts = {}
	for ing, need in pairs(target) do
		out[ing] = (dish[ing] or 0) - need
	end
	for ing, have in pairs(dish) do
		if out[ing] == nil then
			out[ing] = have - (target[ing] or 0)
		end
	end
	return out
end

return DishMath
