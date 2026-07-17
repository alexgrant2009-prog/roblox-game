--!strict
-- CarrySystem (Server)
-- The Cook physically carries an ingredient from a bin to the bowl:
--   Grab at a bin  ->  a scaled ingredient model welds into the Cook's hand.
--   Walk to the bowl -> when close enough it drops in and is added to the dish.
--
-- Grabbing again swaps what you're holding; nothing is added until it reaches
-- the bowl. Holding while the oven runs (baking) just waits until it's free.
-- Everything here is server-authoritative and role-checked.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local IngredientModels = require(script.Parent.IngredientModels)

local CarrySystem = {}

local DEPOSIT_RANGE = 6.5

-- [Player] = { ingredient = string, model = Model }
local carrying: { [Player]: { ingredient: string, model: Model } } = {}

local function removeCarry(player: Player)
	local c = carrying[player]
	if c then
		if c.model then
			c.model:Destroy()
		end
		carrying[player] = nil
	end
end
CarrySystem.clear = removeCarry

function CarrySystem.clearAll()
	for player in pairs(carrying) do
		removeCarry(player)
	end
end

local function getHand(character: Instance): BasePart?
	return character:FindFirstChild("RightHand") -- R15
		or character:FindFirstChild("Right Arm") -- R6
end

-- Scale the model down and rigidly weld it into the hand.
local function attachToHand(model: Model, character: Instance): boolean
	local hand = getHand(character)
	local primary = model.PrimaryPart
	if not (hand and primary) then
		return false
	end

	model:ScaleTo(0.6)
	model:PivotTo(hand.CFrame * CFrame.new(0, 0.2, -1.1))

	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanQuery = false
			d.Massless = true
			if d ~= primary then
				d.Anchored = false
				local w = Instance.new("WeldConstraint")
				w.Part0 = primary
				w.Part1 = d
				w.Parent = primary
			end
		end
	end

	local hw = Instance.new("WeldConstraint")
	hw.Part0 = hand
	hw.Part1 = primary
	hw.Parent = primary
	primary.Anchored = false
	model.Parent = character
	return true
end

function CarrySystem.grab(ctx, player: Player, ingredient: string)
	if not ctx.Roles:can(player, ctx.Roles.Cook) then
		return
	end
	if ctx.State.phase ~= "ACTIVE" then
		return
	end
	local character = player.Character
	if not character then
		return
	end

	removeCarry(player) -- swap out whatever was in hand

	local model = IngredientModels.build(ingredient)
	if not model then
		return
	end
	model:SetAttribute("BakerySpin", nil) -- don't let ClientDecor spin a held item
	model.Name = "Carried_" .. ingredient

	if not attachToHand(model, character) then
		model:Destroy()
		return
	end

	carrying[player] = { ingredient = ingredient, model = model }
	ctx.sfxAt(character:FindFirstChild("HumanoidRootPart"), "AddIngredient")
end

local function deposit(ctx, player: Player)
	local c = carrying[player]
	if not c then
		return
	end
	local dish = ctx.Dish
	if dish.baking or dish.burnt then
		return -- keep holding until the bowl is free again
	end

	local handPos: Vector3? = nil
	if c.model and c.model.PrimaryPart then
		handPos = c.model.PrimaryPart.Position
	end

	removeCarry(player)
	dish:add(c.ingredient, 1)
	ctx.sfxAt(ctx.Kitchen and ctx.Kitchen.mixing.part, "AddIngredient")
	if handPos then
		ctx.tossFx(c.ingredient, handPos) -- little drop from hand into the bowl
	end
	ctx.emitDishChanged()
end

function CarrySystem.init(ctx)
	local bowl = ctx.Kitchen and ctx.Kitchen.mixing.part

	local function hookPlayer(player: Player)
		player.CharacterRemoving:Connect(function()
			removeCarry(player)
		end)
	end
	for _, p in ipairs(Players:GetPlayers()) do
		hookPlayer(p)
	end
	Players.PlayerAdded:Connect(hookPlayer)
	Players.PlayerRemoving:Connect(removeCarry)

	-- Auto-drop when a carrier gets close to the bowl.
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.12 then
			return
		end
		acc = 0
		if not bowl then
			return
		end
		for player, _ in pairs(carrying) do
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local d = hrp.Position - bowl.Position
				if Vector3.new(d.X, 0, d.Z).Magnitude <= DEPOSIT_RANGE then
					deposit(ctx, player)
				end
			end
		end
	end)
end

return CarrySystem
