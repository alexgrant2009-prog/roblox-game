--!strict
-- SubmitStation (Server)
-- Handles the "Serve Dish" prompt: compares the final dish to the front order's
-- recipe, scores it, adjusts reputation, dequeues, and lets the next order slide
-- forward. Cooks only, server-authoritative.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BlackoutBakery")
local DishMath = require(Shared.DishMath)

local SubmitStation = {}

function SubmitStation.handleServe(ctx, player: Player)
	if not ctx.Roles:can(player, ctx.Roles.Cook) then
		return
	end
	if ctx.State.phase ~= "ACTIVE" then
		return
	end

	local front = ctx.Orders:front()
	if not front then
		ctx.announce("No orders up to serve right now.", "info")
		return
	end

	-- A burnt dish can't be served -- scrap it.
	if ctx.Dish.burnt then
		ctx.announce("It's burnt -- scrap it and bake a fresh one.", "info")
		ctx.sfxClient(player, "ServeFail")
		return
	end

	-- Must be baked first (no penalty for trying -- just a nudge).
	if ctx.Config.RequireBake and not ctx.Dish.baked then
		if ctx.Dish:isEmpty() then
			ctx.announce("The bowl's empty -- there's nothing to serve.", "info")
		else
			ctx.announce("It's still raw -- bake it first!", "info")
		end
		ctx.sfxClient(player, "ServeFail")
		return
	end

	local servePart = ctx.Kitchen and ctx.Kitchen.submit.part
	local score = DishMath.matchScore(ctx.Dish:snapshot(), front.recipe.ingredients)

	-- Consume the order and reset the bowl regardless of outcome.
	ctx.Orders:removeFront()
	ctx.Dish:clear()
	ctx.emitDishChanged()

	if score >= ctx.Config.MatchThreshold then
		ctx.State.streak += 1
		local mult = math.min(1 + ctx.Config.StreakMultStep * (ctx.State.streak - 1), ctx.Config.StreakMultMax)
		local points = math.floor(ctx.Config.ScorePerfect * mult)
		ctx.State.score += points
		ctx.State.perfect += 1
		ctx.sfxAt(servePart, "ServePerfect")
		task.delay(0.12, function()
			ctx.sfxAt(servePart, "ServePerfect2") -- two-note success chime
		end)
		local streakTag = (ctx.State.streak >= 2) and (" 🔥x%d"):format(ctx.State.streak) or ""
		ctx.announce(("Perfect %s! +%d%s"):format(front.recipe.name, points, streakTag), "good")
	elseif score >= ctx.Config.PartialThreshold then
		ctx.State.streak = 0
		ctx.State.score += ctx.Config.ScorePartial
		ctx.sfxAt(servePart, "ServePartial")
		ctx.announce(("Close enough on the %s. +%d"):format(front.recipe.name, ctx.Config.ScorePartial), "good")
	else
		ctx.State.streak = 0
		ctx.sfxAt(servePart, "ServeFail")
		ctx.loseRep(ctx.Config.RepLossWrong, ("That was not a %s..."):format(front.recipe.name))
	end

	ctx.Orders:refreshTicket()
	ctx.emitHud()
end

return SubmitStation
