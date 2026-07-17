--!strict
-- KitchenBuilder (Server)
-- Spawns the whole playable kitchen at runtime: floor, spawn pad, ingredient
-- bins, mixing bowl, serve window, reader desk -- each with ProximityPrompts.
-- Because it builds everything in code, the game runs on a bare baseplate; you
-- don't have to hand-place anything in Studio.
--
-- Each interactive prompt carries a "BakeryRole" attribute. The server ignores
-- it (it re-checks role directly), but clients read it to locally hide prompts
-- that aren't for their role (UX only -- see ClientMain).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BlackoutBakery")
local RecipeConfig = require(Shared.RecipeConfig)

local KitchenBuilder = {}

local function makePart(props): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		(p :: any)[k] = v
	end
	return p
end

local function label(parent: Instance, text: string, color: Color3?)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(4.5, 1.4)
	bb.StudsOffset = Vector3.new(0, 2.6, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 70
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Text = text
	tl.TextColor3 = color or Color3.new(1, 1, 1)
	tl.TextScaled = true
	tl.Font = Enum.Font.GothamBold
	tl.TextStrokeTransparency = 0.35
	tl.Parent = bb
	bb.Parent = parent
end

local function prompt(parent: Instance, actionText: string, objectText: string, role: string?, key: Enum.KeyCode?)
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = actionText
	pp.ObjectText = objectText
	pp.HoldDuration = 0
	pp.RequiresLineOfSight = false
	pp.MaxActivationDistance = 9
	pp.KeyboardKeyCode = key or Enum.KeyCode.E
	if role then
		pp:SetAttribute("BakeryRole", role)
	end
	pp.Parent = parent
	return pp
end

function KitchenBuilder.build(ctx)
	local model = Instance.new("Model")
	model.Name = "BlackoutBakeryKitchen"

	-- Floor
	local floor = makePart({
		Name = "KitchenFloor",
		Size = Vector3.new(90, 1, 64),
		Position = Vector3.new(0, 0.5, 0),
		Color = Color3.fromRGB(58, 54, 64),
		Material = Enum.Material.SmoothPlastic,
	})
	floor.Parent = model

	-- Spawn pad
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "BakerySpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 1, 8)
	spawn.Position = Vector3.new(0, 1.5, 26)
	spawn.Color = Color3.fromRGB(92, 82, 104)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Neutral = true
	spawn.Parent = model

	-- Ingredient bins in a row along the back
	local bins = {}
	local order = RecipeConfig.IngredientOrder
	local startX = -(#order - 1) * 5 / 2
	for i, ingName in ipairs(order) do
		local meta = RecipeConfig.Ingredients[ingName]
		local bin = makePart({
			Name = "Bin_" .. ingName,
			Size = Vector3.new(3.6, 3, 3.6),
			Position = Vector3.new(startX + (i - 1) * 5, 2.5, -20),
			Color = meta.color,
			Material = Enum.Material.SmoothPlastic,
		})
		bin.Parent = model
		label(bin, ingName, Color3.new(0, 0, 0))
		local pp = prompt(bin, "Add", ingName, ctx.Roles.Cook)
		pp:SetAttribute("Ingredient", ingName)
		table.insert(bins, { ingredient = ingName, prompt = pp, part = bin })
	end

	-- Mixing bowl: Taster tastes here, Cook can scrap here
	local bowl = makePart({
		Name = "MixingStation",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2, 6.5, 6.5),
		Position = Vector3.new(-12, 3, 6),
		Orientation = Vector3.new(0, 0, 90),
		Color = Color3.fromRGB(178, 178, 190),
		Material = Enum.Material.Metal,
	})
	bowl.Parent = model
	label(bowl, "Mixing Bowl", Color3.new(1, 1, 1))
	local tastePrompt = prompt(bowl, "Taste", "Mixing Bowl", ctx.Roles.Taster, Enum.KeyCode.E)
	local discardPrompt = prompt(bowl, "Scrap Bowl", "Mixing Bowl", ctx.Roles.Cook, Enum.KeyCode.Q)

	-- Serve window (the oven pass)
	local pass = makePart({
		Name = "SubmitStation",
		Size = Vector3.new(9, 5, 4),
		Position = Vector3.new(14, 2.5, 6),
		Color = Color3.fromRGB(120, 85, 60),
		Material = Enum.Material.WoodPlanks,
	})
	pass.Parent = model
	label(pass, "Serve Window", Color3.fromRGB(255, 240, 180))
	local servePrompt = prompt(pass, "Serve Dish", "Serve Window", ctx.Roles.Cook, Enum.KeyCode.F)

	-- Reader's desk (flavor / meeting point)
	local podium = makePart({
		Name = "ReaderPodium",
		Size = Vector3.new(4, 4, 3),
		Position = Vector3.new(0, 2, 16),
		Color = Color3.fromRGB(70, 90, 140),
		Material = Enum.Material.SmoothPlastic,
	})
	podium.Parent = model
	label(podium, "Reader's Desk", Color3.fromRGB(180, 210, 255))

	model.Parent = workspace

	return {
		model = model,
		bins = bins,
		mixing = { part = bowl, tastePrompt = tastePrompt, discardPrompt = discardPrompt },
		submit = { part = pass, servePrompt = servePrompt },
	}
end

return KitchenBuilder
