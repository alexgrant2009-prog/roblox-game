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
	if ctx.Roles:getRole(player) ~= ctx.Roles.Cook then
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

	local score = DishMath.matchScore(ctx.Dish:snapshot(), front.recipe.ingredients)

	-- Consume the order and reset the bowl regardless of outcome.
	ctx.Orders:removeFront()
	ctx.Dish:clear()
	ctx.emitDishChanged()

	if score >= ctx.Config.MatchThreshold then
		ctx.State.score += ctx.Config.ScorePerfect
		ctx.State.perfect += 1
		ctx.announce(("Perfect %s! +%d"):format(front.recipe.name, ctx.Config.ScorePerfect), "good")
	elseif score >= ctx.Config.PartialThreshold then
		ctx.State.score += ctx.Config.ScorePartial
		ctx.announce(("Close enough on the %s. +%d"):format(front.recipe.name, ctx.Config.ScorePartial), "good")
	else
		ctx.loseRep(ctx.Config.RepLossWrong, ("That was not a %s..."):format(front.recipe.name))
	end

	ctx.Orders:refreshTicket()
	ctx.emitHud()
end

return SubmitStation
