--!strict
-- IngredientStation (Server)
-- Handles the ProximityPrompt triggers on the bins and the mixing bowl.
-- Every handler re-checks the acting player's role on the SERVER before doing
-- anything -- this is the authoritative gate. Client-side prompt hiding is only
-- UX; a Reader who re-enables a bin prompt via exploit still gets rejected here.

local IngredientStation = {}

-- Add one unit of an ingredient to the shared bowl. Cooks only.
function IngredientStation.handleAdd(ctx, player: Player, ingredient: string)
	if ctx.Roles:getRole(player) ~= ctx.Roles.Cook then
		return
	end
	if ctx.State.phase ~= "ACTIVE" then
		return
	end
	ctx.Dish:add(ingredient, 1)
	ctx.emitDishChanged()
end

-- Taste the in-progress dish -> fuzzy hint fired back to this Taster only.
function IngredientStation.handleTaste(ctx, player: Player)
	if ctx.Roles:getRole(player) ~= ctx.Roles.Taster then
		return
	end
	if ctx.State.phase ~= "ACTIVE" then
		return
	end
	local target = ctx.getFrontRecipe()
	local hint = ctx.TasteService.hintFor(ctx.Dish:snapshot(), target)
	ctx.Remotes.TasteHint:FireClient(player, hint) -- Taster only
end

-- Scrap the bowl and start over (soft fail). Cooks only, and only if enabled.
function IngredientStation.handleDiscard(ctx, player: Player)
	if not ctx.Config.AllowDiscard then
		return
	end
	if ctx.Roles:getRole(player) ~= ctx.Roles.Cook then
		return
	end
	if ctx.State.phase ~= "ACTIVE" then
		return
	end
	if ctx.Dish.total == 0 then
		return
	end
	ctx.Dish:clear()
	ctx.emitDishChanged()
	ctx.announce("The bowl was scrapped -- starting fresh.", "info")
end

return IngredientStation
