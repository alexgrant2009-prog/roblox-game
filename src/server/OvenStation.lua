--!strict
-- OvenStation (Server)
-- Handles the "Bake" prompt on the oven. The Cook's flow is now:
--   add ingredients  ->  BAKE  ->  serve
-- A dish can't be served until it's baked (SubmitStation enforces that). Adding
-- an ingredient after baking un-bakes it, so a late correction means re-baking.
--
-- Baking takes GameConfig.BakeDuration seconds. The oven glows while it runs,
-- and a stale bake (bowl scrapped or round ended mid-bake) can't complete
-- thanks to the token from DishState:startBake().

local OvenStation = {}

local HOT_COLOR = Color3.fromRGB(255, 120, 40)

function OvenStation.handleBake(ctx, player: Player)
	if ctx.Roles:getRole(player) ~= ctx.Roles.Cook then
		return
	end
	if ctx.State.phase ~= "ACTIVE" then
		return
	end

	local dish = ctx.Dish
	if dish:isEmpty() then
		ctx.sfxClient(player, "ServeFail")
		ctx.announce("Nothing in the bowl to bake!", "info")
		return
	end
	if dish.baking then
		return
	end
	if dish.baked then
		ctx.announce("That's already baked -- serve it or add more.", "info")
		return
	end

	local oven = ctx.Kitchen and ctx.Kitchen.oven
	local part = oven and oven.part

	local token = dish:startBake()
	ctx.emitDishChanged()
	ctx.sfxAt(part, "BakeStart")
	ctx.announce("Into the oven it goes...", "info")

	-- Glow the oven while it bakes.
	local originalColor, originalMaterial
	if part then
		originalColor, originalMaterial = part.Color, part.Material
		part.Material = Enum.Material.Neon
		part.Color = HOT_COLOR
	end

	task.delay(ctx.Config.BakeDuration, function()
		if part then
			part.Material = originalMaterial
			part.Color = originalColor
		end
		if dish:finishBake(token) then
			ctx.sfxAt(part, "BakeDone")
			ctx.emitDishChanged()
			ctx.announce("Ding! Fresh out of the oven.", "good")
		end
	end)
end

return OvenStation
