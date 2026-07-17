--!strict
-- OvenStation (Server)
-- The bake step is a timing challenge. The Cook's flow:
--   add ingredients  ->  BAKE (put in)  ->  wait for the READY window  ->
--   TAKE OUT in time  ->  serve
--
-- The oven prompt toggles: "Bake" to put the dish in, "Take Out" to pull it.
--   * Pulled BEFORE BakeReadyTime  -> still raw (no harm, put it back in).
--   * Pulled DURING the ready window (BakeReadyTime .. BakeBurnTime) -> baked.
--   * Left past BakeBurnTime        -> BURNT: ruined, must be scrapped.
--
-- A live gauge above the oven (built by KitchenBuilder) shows progress, the
-- ready line, and the state text so the timing is readable. The oven glows
-- from cold -> hot -> charred to reinforce it.
--
-- A bake token (DishState.bakeId) means a scrap or round-end mid-bake can't
-- sneakily complete or leave the oven glowing.

local OvenStation = {}

local COLD = Color3.fromRGB(70, 68, 74) -- matches the oven's idle color
local WARM = Color3.fromRGB(255, 120, 40)
local READY = Color3.fromRGB(120, 230, 120)
local HOT = Color3.fromRGB(235, 70, 25)
local CHARRED = Color3.fromRGB(28, 22, 20)

local function setPrompt(oven, text: string)
	if oven and oven.bakePrompt then
		oven.bakePrompt.ActionText = text
	end
end

local function showGauge(oven, on: boolean)
	if oven and oven.gauge and oven.gauge.gui then
		oven.gauge.gui.Enabled = on
	end
end

-- Paint the oven + gauge for the given elapsed bake time.
local function updateVisual(oven, e: number, cfg)
	local ready, burn = cfg.BakeReadyTime, cfg.BakeBurnTime
	local frac = math.clamp(e / burn, 0, 1)
	local color, labelText, labelColor, fillColor

	if e < ready then
		color = COLD:Lerp(WARM, math.clamp(e / ready, 0, 1))
		labelText = "Baking..."
		labelColor = Color3.fromRGB(255, 200, 150)
		fillColor = WARM
	else
		local t = math.clamp((e - ready) / math.max(0.01, burn - ready), 0, 1)
		color = READY:Lerp(HOT, t)
		fillColor = color
		if t > 0.6 then
			labelText = "TAKE IT OUT!"
			labelColor = Color3.fromRGB(255, 130, 110)
		else
			labelText = "READY!"
			labelColor = Color3.fromRGB(150, 255, 150)
		end
	end

	if oven.part then
		oven.part.Material = Enum.Material.Neon
		oven.part.Color = color
	end
	local g = oven.gauge
	if g then
		if g.label then
			g.label.Text = labelText
			g.label.TextColor3 = labelColor
		end
		if g.fill then
			g.fill.Size = UDim2.new(frac, 0, 1, 0)
			g.fill.BackgroundColor3 = fillColor
		end
	end
end

local function setCharred(oven)
	if oven.part then
		oven.part.Material = Enum.Material.DiamondPlate
		oven.part.Color = CHARRED
	end
	local g = oven.gauge
	if g then
		if g.label then
			g.label.Text = "BURNT!"
			g.label.TextColor3 = Color3.fromRGB(130, 130, 130)
		end
		if g.fill then
			g.fill.Size = UDim2.new(1, 0, 1, 0)
			g.fill.BackgroundColor3 = CHARRED
		end
	end
end

-- Return the oven to its idle look (used on take-out, scrap, and round reset).
function OvenStation.idle(oven)
	if not oven then
		return
	end
	if oven.part then
		oven.part.Material = Enum.Material.DiamondPlate
		oven.part.Color = COLD
	end
	setPrompt(oven, "Bake")
	showGauge(oven, false)
end

function OvenStation.startBake(ctx, oven)
	local dish = ctx.Dish
	local token = dish:startBake()

	setPrompt(oven, "Take Out")
	showGauge(oven, true)
	updateVisual(oven, 0, ctx.Config)
	ctx.sfxAt(oven.part, "BakeStart")
	ctx.announce("Into the oven -- don't let it burn!", "info")
	ctx.emitDishChanged()

	task.spawn(function()
		local readyPinged = false
		while dish.baking and dish.bakeId == token do
			local dt = task.wait(0.15)
			if not (dish.baking and dish.bakeId == token) then
				break -- taken out / scrapped / round ended while we were waiting
			end
			dish.bakeElapsed += dt
			local e = dish.bakeElapsed

			if e >= ctx.Config.BakeBurnTime then
				dish:burn()
				setPrompt(oven, "Bake")
				setCharred(oven)
				ctx.sfxAt(oven.part, "ServeFail")
				ctx.announce("It burnt to a crisp! Scrap it and start over.", "bad")
				if ctx.Config.RepLossBurn > 0 then
					ctx.loseRep(ctx.Config.RepLossBurn, nil)
				end
				ctx.emitDishChanged()
				task.delay(1.5, function()
					if dish.burnt then
						showGauge(oven, false)
					end
				end)
				break
			end

			updateVisual(oven, e, ctx.Config)
			if not readyPinged and e >= ctx.Config.BakeReadyTime then
				readyPinged = true
				ctx.sfxAt(oven.part, "BakeDone") -- "ding" when the window opens
			end
			ctx.emitHud()
		end

		-- If our bake was superseded by a clear/round-reset (not a take-out or
		-- burn we already handled), leave the oven looking idle.
		if dish.bakeId ~= token and not dish.baking and not dish.burnt then
			OvenStation.idle(oven)
		end
	end)
end

function OvenStation.takeOut(ctx, oven)
	local dish = ctx.Dish
	local e = dish.bakeElapsed or 0
	if e < ctx.Config.BakeReadyTime then
		dish:cancelBake()
		OvenStation.idle(oven)
		ctx.sfxAt(oven.part, "Scrap")
		ctx.announce("Too soon -- still raw. Back in it goes.", "info")
	else
		dish:finishBake()
		OvenStation.idle(oven)
		ctx.sfxAt(oven.part, "BakeDone")
		ctx.announce("Perfectly baked -- serve it!", "good")
	end
	ctx.emitDishChanged()
end

function OvenStation.handleBake(ctx, player: Player)
	if ctx.Roles:getRole(player) ~= ctx.Roles.Cook then
		return
	end
	if ctx.State.phase ~= "ACTIVE" then
		return
	end

	local oven = ctx.Kitchen and ctx.Kitchen.oven
	if not oven then
		return
	end
	local dish = ctx.Dish

	-- If it's already in the oven, this press takes it out.
	if dish.baking then
		OvenStation.takeOut(ctx, oven)
		return
	end
	if dish.burnt then
		ctx.announce("It's burnt -- scrap the bowl before baking again.", "info")
		return
	end
	if dish:isEmpty() then
		ctx.sfxClient(player, "ServeFail")
		ctx.announce("Nothing in the bowl to bake!", "info")
		return
	end
	if dish.baked then
		ctx.announce("Already baked -- serve it or add more.", "info")
		return
	end

	OvenStation.startBake(ctx, oven)
end

return OvenStation
