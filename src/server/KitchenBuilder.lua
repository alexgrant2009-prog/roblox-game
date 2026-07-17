--!strict
-- KitchenBuilder (Server)
-- Builds the whole playable kitchen at runtime: a walled room with warm
-- lighting, a back counter of ingredient bins, a prep island with the mixing
-- bowl, an oven, and a serve window -- each with ProximityPrompts. Because it's
-- all built in code, the game runs on a bare baseplate; nothing is hand-placed.
--
-- Each interactive prompt carries a "BakeryRole" attribute so clients can hide
-- prompts that aren't for their role (UX only -- the server re-checks role).

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BlackoutBakery")
local RecipeConfig = require(Shared.RecipeConfig)
local IngredientModels = require(script.Parent.IngredientModels)

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

-- A floating "pill" label: dark rounded background + text, so it stays readable
-- against the sky and doesn't smear into its neighbors like plain text does.
local function pill(adornee: Instance, text: string, opts)
	opts = opts or {}
	local bb = Instance.new("BillboardGui")
	bb.Name = "Label"
	bb.Adornee = adornee
	bb.Size = opts.size or UDim2.fromOffset(96, 28)
	bb.StudsOffset = Vector3.new(0, opts.offsetY or 3, 0)
	bb.AlwaysOnTop = opts.onTop == true
	bb.MaxDistance = opts.maxDistance or 65
	bb.LightInfluence = 0

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = opts.bg or Color3.fromRGB(22, 20, 28)
	frame.BackgroundTransparency = opts.bgTransparency or 0.25
	frame.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.35, 0)
	corner.Parent = frame

	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.new(1, -8, 1, -6)
	tl.Position = UDim2.new(0, 4, 0, 3)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.GothamBold
	tl.TextScaled = true
	tl.Text = text
	tl.TextColor3 = opts.color or Color3.fromRGB(240, 240, 245)
	tl.Parent = frame
	frame.Parent = bb
	bb.Parent = adornee
	return tl
end

-- Paint a name directly onto a part's vertical faces. Unlike a floating
-- billboard, a surface label can't overlap its neighbors. Both Front and Back
-- are painted so one always faces the aisle.
local function faceLabel(part: BasePart, text: string)
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local sg = Instance.new("SurfaceGui")
		sg.Name = "FaceLabel"
		sg.Face = face
		sg.CanvasSize = Vector2.new(400, 320)
		sg.LightInfluence = 0
		sg.Parent = part

		local band = Instance.new("TextLabel")
		band.AnchorPoint = Vector2.new(0.5, 0.5)
		band.Position = UDim2.fromScale(0.5, 0.5)
		band.Size = UDim2.fromScale(0.9, 0.4)
		band.BackgroundColor3 = Color3.fromRGB(22, 20, 28)
		band.BackgroundTransparency = 0.15
		band.Font = Enum.Font.GothamBold
		band.TextScaled = true
		band.TextColor3 = Color3.fromRGB(245, 245, 250)
		band.Text = text
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.3, 0)
		corner.Parent = band
		band.Parent = sg
	end
end

local function prompt(parent: Instance, actionText: string, objectText: string, role: string?, key: Enum.KeyCode?)
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = actionText
	pp.ObjectText = objectText
	pp.HoldDuration = 0
	pp.RequiresLineOfSight = false
	pp.MaxActivationDistance = 10
	pp.KeyboardKeyCode = key or Enum.KeyCode.E
	if role then
		pp:SetAttribute("BakeryRole", role)
	end
	pp.Parent = parent
	return pp
end

local function pointLight(parent: BasePart, color: Color3, brightness: number, range: number)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness
	l.Range = range
	l.Parent = parent
end

local function setupLighting()
	Lighting.Ambient = Color3.fromRGB(120, 110, 120)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 148, 158)
	Lighting.Brightness = 2.4
	Lighting.ClockTime = 14
	Lighting.EnvironmentDiffuseScale = 0.45
	Lighting.EnvironmentSpecularScale = 0.4
	Lighting.GlobalShadows = true
	Lighting.FogEnd = 900
end

function KitchenBuilder.build(ctx)
	setupLighting()

	local model = Instance.new("Model")
	model.Name = "BlackoutBakeryKitchen"

	-- Floor (warm wood) ----------------------------------------------------
	local floor = makePart({
		Name = "KitchenFloor",
		Size = Vector3.new(84, 2, 66),
		Position = Vector3.new(0, -1, 0),
		Color = Color3.fromRGB(196, 158, 118),
		Material = Enum.Material.WoodPlanks,
	})
	floor.Parent = model

	-- Walls (cream) --------------------------------------------------------
	local WALL = Color3.fromRGB(244, 236, 224)
	local function wall(name, size, pos)
		local w = makePart({
			Name = name,
			Size = size,
			Position = pos,
			Color = WALL,
			Material = Enum.Material.SmoothPlastic,
		})
		w.Parent = model
		return w
	end
	local northWall = wall("WallNorth", Vector3.new(84, 22, 2), Vector3.new(0, 11, -33))
	wall("WallSouth", Vector3.new(84, 22, 2), Vector3.new(0, 11, 33))
	wall("WallEast", Vector3.new(2, 22, 66), Vector3.new(42, 11, 0))
	wall("WallWest", Vector3.new(2, 22, 66), Vector3.new(-42, 11, 0))

	-- Back-wall sign
	local sign = Instance.new("SurfaceGui")
	sign.Name = "BakerySign"
	sign.Face = Enum.NormalId.Back -- inner (+Z) face
	sign.CanvasSize = Vector2.new(1000, 260)
	sign.LightInfluence = 0
	sign.Parent = northWall
	local signText = Instance.new("TextLabel")
	signText.AnchorPoint = Vector2.new(0.5, 1)
	signText.Position = UDim2.fromScale(0.5, 0.92)
	signText.Size = UDim2.fromScale(0.86, 0.42)
	signText.BackgroundTransparency = 1
	signText.Font = Enum.Font.GothamBlack
	signText.TextScaled = true
	signText.Text = "BLACKOUT BAKERY"
	signText.TextColor3 = Color3.fromRGB(255, 214, 150)
	signText.TextStrokeTransparency = 0.5
	signText.Parent = sign

	-- Spawn (no forcefield), south side, facing the kitchen ----------------
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "BakerySpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 1, 8)
	spawn.Position = Vector3.new(0, 0.5, 20)
	spawn.Color = Color3.fromRGB(120, 108, 130)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Neutral = true
	spawn.Duration = 0 -- no spawn forcefield
	spawn.Parent = model

	-- Back counter + ingredient bins ---------------------------------------
	local order = RecipeConfig.IngredientOrder
	local step = 6.6
	local span = (#order - 1) * step
	local startX = -span / 2

	local backCounter = makePart({
		Name = "IngredientCounter",
		Size = Vector3.new(span + 8, 4, 5),
		Position = Vector3.new(0, 2, -19),
		Color = Color3.fromRGB(214, 210, 220),
		Material = Enum.Material.Concrete,
	})
	backCounter.Parent = model

	local bins = {}
	for i, ingName in ipairs(order) do
		local meta = RecipeConfig.Ingredients[ingName]
		local x = startX + (i - 1) * step
		-- Neutral crate; the ingredient's colour/identity comes from the model
		-- floating above it. A thin band of the ingredient colour rims the top.
		local bin = makePart({
			Name = "Bin_" .. ingName,
			Size = Vector3.new(4, 3.2, 4),
			Position = Vector3.new(x, 5.6, -19),
			Color = Color3.fromRGB(126, 96, 66),
			Material = Enum.Material.WoodPlanks,
		})
		bin.Parent = model
		local rim = makePart({
			Name = "BinRim",
			Size = Vector3.new(4.2, 0.5, 4.2),
			Position = Vector3.new(x, 7.3, -19),
			Color = meta.color,
			Material = Enum.Material.SmoothPlastic,
		})
		rim.Parent = bin
		faceLabel(bin, meta.display)

		-- Floating, animated ingredient display above the bin.
		local display = IngredientModels.build(ingName)
		if display then
			display.Parent = bin
			display:PivotTo(CFrame.new(x, 9.4, -19))
		end

		local pp = prompt(bin, "Grab", ingName, ctx.Roles.Cook)
		pp:SetAttribute("Ingredient", ingName)
		table.insert(bins, { ingredient = ingName, prompt = pp, part = bin })
	end

	-- Prep island + mixing bowl (center) -----------------------------------
	local island = makePart({
		Name = "PrepIsland",
		Size = Vector3.new(14, 4, 7),
		Position = Vector3.new(0, 2, -2),
		Color = Color3.fromRGB(214, 210, 220),
		Material = Enum.Material.Concrete,
	})
	island.Parent = model

	local bowl = makePart({
		Name = "MixingStation",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2.5, 6, 6),
		Position = Vector3.new(0, 5.5, -2),
		Orientation = Vector3.new(0, 0, 90),
		Color = Color3.fromRGB(180, 182, 192),
		Material = Enum.Material.Metal,
	})
	bowl.Parent = model
	pill(bowl, "Mixing Bowl", { offsetY = 3, color = Color3.fromRGB(230, 240, 255), size = UDim2.fromOffset(120, 28) })
	-- Two prompts on one part overlap and fight each other, so mount each on its
	-- own attachment offset to opposite sides of the bowl.
	local tasteAtt = Instance.new("Attachment")
	tasteAtt.Name = "TastePoint"
	tasteAtt.Parent = bowl
	tasteAtt.WorldPosition = Vector3.new(-2, 6.2, 0)
	local scrapAtt = Instance.new("Attachment")
	scrapAtt.Name = "ScrapPoint"
	scrapAtt.Parent = bowl
	scrapAtt.WorldPosition = Vector3.new(2, 6.2, 0)
	local tastePrompt = prompt(tasteAtt, "Taste", "Mixing Bowl", ctx.Roles.Taster, Enum.KeyCode.E)
	local discardPrompt = prompt(scrapAtt, "Scrap Bowl", "Mixing Bowl", ctx.Roles.Cook, Enum.KeyCode.Q)

	-- Oven (right) ---------------------------------------------------------
	local oven = makePart({
		Name = "OvenStation",
		Size = Vector3.new(8, 8, 6),
		Position = Vector3.new(22, 4, -2),
		Color = Color3.fromRGB(70, 68, 74),
		Material = Enum.Material.DiamondPlate,
	})
	oven.Parent = model
	local door = makePart({
		Name = "OvenDoor",
		Size = Vector3.new(5.4, 4.4, 0.4),
		Position = Vector3.new(22, 4, -5.1),
		Color = Color3.fromRGB(28, 26, 32),
		Material = Enum.Material.Glass,
	})
	door.Parent = oven
	pill(oven, "Oven", { offsetY = 4.4, color = Color3.fromRGB(255, 190, 130), size = UDim2.fromOffset(90, 28) })
	local bakePrompt = prompt(oven, "Bake", "Oven", ctx.Roles.Cook, Enum.KeyCode.R)

	-- Live bake gauge (hidden until baking) --------------------------------
	local gauge = Instance.new("BillboardGui")
	gauge.Name = "BakeGauge"
	gauge.Size = UDim2.fromOffset(220, 62)
	gauge.StudsOffset = Vector3.new(0, 6.6, 0)
	gauge.AlwaysOnTop = true
	gauge.MaxDistance = 90
	gauge.LightInfluence = 0
	gauge.Enabled = false
	gauge.Adornee = oven
	gauge.Parent = oven

	local gLabel = Instance.new("TextLabel")
	gLabel.Size = UDim2.fromScale(1, 0.55)
	gLabel.BackgroundTransparency = 1
	gLabel.Font = Enum.Font.GothamBold
	gLabel.TextScaled = true
	gLabel.Text = "Baking..."
	gLabel.TextColor3 = Color3.fromRGB(255, 200, 150)
	gLabel.TextStrokeTransparency = 0.3
	gLabel.Parent = gauge

	local barBg = Instance.new("Frame")
	barBg.AnchorPoint = Vector2.new(0.5, 1)
	barBg.Position = UDim2.fromScale(0.5, 1)
	barBg.Size = UDim2.fromScale(0.96, 0.34)
	barBg.BackgroundColor3 = Color3.fromRGB(20, 18, 22)
	barBg.BorderSizePixel = 0
	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0.5, 0)
	bgCorner.Parent = barBg
	barBg.Parent = gauge

	local barFill = Instance.new("Frame")
	barFill.Size = UDim2.new(0, 0, 1, 0)
	barFill.BackgroundColor3 = Color3.fromRGB(255, 120, 40)
	barFill.BorderSizePixel = 0
	local bfCorner = Instance.new("UICorner")
	bfCorner.CornerRadius = UDim.new(0.5, 0)
	bfCorner.Parent = barFill
	barFill.Parent = barBg

	local readyFrac = ctx.Config.BakeReadyTime / ctx.Config.BakeBurnTime
	local marker = Instance.new("Frame")
	marker.AnchorPoint = Vector2.new(0.5, 0.5)
	marker.Position = UDim2.fromScale(readyFrac, 0.5)
	marker.Size = UDim2.new(0, 3, 1, 2)
	marker.BackgroundColor3 = Color3.fromRGB(150, 255, 150)
	marker.BorderSizePixel = 0
	marker.ZIndex = 2
	marker.Parent = barBg

	-- Serve window (left) --------------------------------------------------
	local pass = makePart({
		Name = "SubmitStation",
		Size = Vector3.new(9, 5, 4),
		Position = Vector3.new(-22, 2.5, -2),
		Color = Color3.fromRGB(150, 110, 75),
		Material = Enum.Material.WoodPlanks,
	})
	pass.Parent = model
	pill(pass, "Serve Window", { offsetY = 3.4, color = Color3.fromRGB(255, 240, 190), size = UDim2.fromOffset(130, 28) })
	local servePrompt = prompt(pass, "Serve Dish", "Serve Window", ctx.Roles.Cook, Enum.KeyCode.F)

	-- Reader's desk (near spawn) -------------------------------------------
	local podium = makePart({
		Name = "ReaderPodium",
		Size = Vector3.new(6, 4, 3),
		Position = Vector3.new(0, 2, 12),
		Color = Color3.fromRGB(70, 90, 140),
		Material = Enum.Material.SmoothPlastic,
	})
	podium.Parent = model
	local screen = makePart({
		Name = "ReaderScreen",
		Size = Vector3.new(5, 3, 0.4),
		Position = Vector3.new(0, 5.4, 12),
		Color = Color3.fromRGB(24, 26, 40),
		Material = Enum.Material.SmoothPlastic,
	})
	screen.Orientation = Vector3.new(-18, 0, 0)
	screen.Parent = podium
	pill(podium, "Reader's Desk", { offsetY = 5, color = Color3.fromRGB(190, 215, 255), size = UDim2.fromOffset(130, 28) })

	-- Warm lights over the stations ---------------------------------------
	pointLight(island, Color3.fromRGB(255, 235, 200), 1.6, 26)
	pointLight(oven, Color3.fromRGB(255, 180, 120), 1.2, 20)
	pointLight(backCounter, Color3.fromRGB(255, 240, 215), 1.2, 30)
	pointLight(pass, Color3.fromRGB(255, 235, 205), 1.2, 20)

	model.Parent = workspace

	return {
		model = model,
		bins = bins,
		mixing = { part = bowl, tastePrompt = tastePrompt, discardPrompt = discardPrompt },
		oven = { part = oven, bakePrompt = bakePrompt, gauge = { gui = gauge, label = gLabel, fill = barFill } },
		submit = { part = pass, servePrompt = servePrompt },
	}
end

return KitchenBuilder
