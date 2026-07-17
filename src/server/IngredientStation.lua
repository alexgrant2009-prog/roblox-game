--!strict
-- IngredientStation (Server)
-- Handles the mixing-bowl prompts (Taste and Scrap). Every handler re-checks the
-- acting player's role on the SERVER -- this is the authoritative gate; the
-- client-side prompt hiding is only UX. (Grabbing ingredients at the bins is
-- handled by CarrySystem, which carries them to the bowl.)

local IngredientStation = {}

-- Taste the in-progress dish -> fuzzy hint fired back to this Taster only.
function IngredientStation.handleTaste(ctx, player: Player)
	if not ctx.Roles:can(player, ctx.Roles.Taster) then
		return
	end
	if ctx.State.phase ~= "ACTIVE" then
		return
	end
	local target = ctx.getFrontRecipe()
	local hint = ctx.TasteService.hintFor(ctx.Dish:snapshot(), target)
	ctx.Remotes.TasteHint:FireClient(player, hint) -- Taster only
	ctx.sfxClient(player, "Taste")
end

-- Scrap the bowl and start over (soft fail). Cooks only, and only if enabled.
function IngredientStation.handleDiscard(ctx, player: Player)
	if not ctx.Roles:can(player, ctx.Roles.Cook) then
		return
	end
	if ctx.State.phase ~= "ACTIVE" then
		return
	end
	if ctx.Dish.baking then
		return -- let the oven finish before scrapping
	end
	-- A burnt dish can always be scrapped -- otherwise a hard-fail (AllowDiscard
	-- off) round would soft-lock. A non-burnt dish only when discard is allowed.
	if not ctx.Dish.burnt then
		if not ctx.Config.AllowDiscard then
			return
		end
		if ctx.Dish.total == 0 then
			return
		end
	end
	local wasBurnt = ctx.Dish.burnt
	ctx.Dish:clear()
	if ctx.resetOven then
		ctx.resetOven()
	end
	ctx.sfxAt(ctx.Kitchen and ctx.Kitchen.mixing.part, "Scrap")
	ctx.emitDishChanged()
	ctx.announce(wasBurnt and "Tossed the burnt one -- fresh start." or "The bowl was scrapped -- starting fresh.", "info")
end

return IngredientStation
