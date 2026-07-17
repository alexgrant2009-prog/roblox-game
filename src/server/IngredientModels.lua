--!strict
-- IngredientModels (Server)
-- Builds a small, recognizable display model for each ingredient out of parts
-- (no external assets needed). Each is centered on the origin with a PrimaryPart
-- so KitchenBuilder can PivotTo it above a bin, and tagged with the "BakerySpin"
-- attribute so the client bobs + spins it (see ClientDecor).

local IngredientModels = {}

local function piece(parent: Instance, props): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = props.Material or Enum.Material.SmoothPlastic
	for k, v in pairs(props) do
		if k ~= "Material" then
			(p :: any)[k] = v
		end
	end
	p.Parent = parent
	return p
end

local function ball(parent, size: Vector3, cf: CFrame, color: Color3, mat, extra)
	local props = { Shape = Enum.PartType.Ball, Size = size, CFrame = cf, Color = color, Material = mat }
	if extra then
		for k, v in pairs(extra) do
			props[k] = v
		end
	end
	return piece(parent, props)
end

local function box(parent, size: Vector3, cf: CFrame, color: Color3, mat, extra)
	local props = { Size = size, CFrame = cf, Color = color, Material = mat }
	if extra then
		for k, v in pairs(extra) do
			props[k] = v
		end
	end
	return piece(parent, props)
end

-- Vertical cylinder (long axis rotated onto Y).
local function vcyl(parent, height: number, diameter: number, cf: CFrame, color: Color3, mat, extra)
	local props = {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, diameter, diameter),
		CFrame = cf * CFrame.Angles(0, 0, math.rad(90)),
		Color = color,
		Material = mat,
	}
	if extra then
		for k, v in pairs(extra) do
			props[k] = v
		end
	end
	return piece(parent, props)
end

-- Horizontal cylinder (stick) along X, tiltable.
local function stick(parent, length: number, diameter: number, cf: CFrame, color: Color3, mat)
	return piece(parent, {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(length, diameter, diameter),
		CFrame = cf,
		Color = color,
		Material = mat,
	})
end

-- Each builder returns the model's PrimaryPart.
local builders = {}

function builders.Flour(m)
	local sack = ball(m, Vector3.new(1.7, 1.9, 1.4), CFrame.new(0, 0, 0), Color3.fromRGB(224, 202, 162), Enum.Material.Sand)
	ball(m, Vector3.new(0.8, 0.6, 0.8), CFrame.new(0, 1.0, 0), Color3.fromRGB(196, 172, 130), Enum.Material.Sand)
	box(m, Vector3.new(0.9, 0.5, 0.02), CFrame.new(0, -0.2, 0.72), Color3.fromRGB(245, 240, 232), Enum.Material.SmoothPlastic)
	return sack
end

function builders.Sugar(m)
	local c1 = box(m, Vector3.new(0.95, 0.95, 0.95), CFrame.new(0, -0.35, 0), Color3.fromRGB(250, 250, 252), Enum.Material.Ice, { Reflectance = 0.12 })
	box(m, Vector3.new(0.85, 0.85, 0.85), CFrame.new(0.55, 0.35, 0.1) * CFrame.Angles(0, math.rad(20), 0), Color3.fromRGB(248, 248, 250), Enum.Material.Ice, { Reflectance = 0.12 })
	box(m, Vector3.new(0.8, 0.8, 0.8), CFrame.new(-0.45, 0.3, -0.15) * CFrame.Angles(0, math.rad(-15), 0), Color3.fromRGB(252, 252, 255), Enum.Material.Ice, { Reflectance = 0.12 })
	return c1
end

function builders.Butter(m)
	local stickPart = box(m, Vector3.new(1.9, 0.75, 0.95), CFrame.new(0, 0, 0), Color3.fromRGB(246, 220, 120), Enum.Material.SmoothPlastic)
	box(m, Vector3.new(1.5, 0.12, 0.98), CFrame.new(-0.1, 0.42, 0), Color3.fromRGB(238, 236, 226), Enum.Material.SmoothPlastic)
	return stickPart
end

function builders.Eggs(m)
	local e1 = ball(m, Vector3.new(0.9, 1.15, 0.9), CFrame.new(-0.45, -0.05, 0) * CFrame.Angles(0, 0, math.rad(10)), Color3.fromRGB(250, 240, 216), Enum.Material.SmoothPlastic)
	ball(m, Vector3.new(0.9, 1.15, 0.9), CFrame.new(0.45, 0.05, 0.25) * CFrame.Angles(0, 0, math.rad(-8)), Color3.fromRGB(246, 234, 205), Enum.Material.SmoothPlastic)
	return e1
end

function builders.Milk(m)
	local body = box(m, Vector3.new(1.15, 1.5, 1.15), CFrame.new(0, 0, 0), Color3.fromRGB(246, 246, 250), Enum.Material.SmoothPlastic)
	-- gable top
	local roof = Instance.new("WedgePart")
	roof.Anchored = true
	roof.CanCollide = false
	roof.CanQuery = false
	roof.Size = Vector3.new(1.15, 0.5, 0.58)
	roof.Color = Color3.fromRGB(238, 238, 244)
	roof.Material = Enum.Material.SmoothPlastic
	roof.CFrame = CFrame.new(0, 0.98, 0.29)
	roof.Parent = m
	local roof2 = roof:Clone()
	roof2.CFrame = CFrame.new(0, 0.98, -0.29) * CFrame.Angles(0, math.rad(180), 0)
	roof2.Parent = m
	box(m, Vector3.new(1.17, 0.42, 1.17), CFrame.new(0, -0.1, 0), Color3.fromRGB(70, 120, 220), Enum.Material.SmoothPlastic)
	return body
end

function builders.Cocoa(m)
	local bar = box(m, Vector3.new(1.5, 0.5, 0.95), CFrame.new(0, -0.3, 0), Color3.fromRGB(80, 50, 38), Enum.Material.SmoothPlastic)
	ball(m, Vector3.new(1.1, 0.5, 1.1), CFrame.new(0.15, 0.15, 0.2), Color3.fromRGB(98, 62, 46), Enum.Material.Sand)
	box(m, Vector3.new(0.42, 0.14, 0.42), CFrame.new(-0.4, 0.05, -0.1), Color3.fromRGB(70, 44, 34), Enum.Material.SmoothPlastic)
	return bar
end

function builders.Berries(m)
	local root = ball(m, Vector3.new(0.62, 0.62, 0.62), CFrame.new(0, -0.1, 0), Color3.fromRGB(150, 40, 90), Enum.Material.SmoothPlastic)
	ball(m, Vector3.new(0.58, 0.58, 0.58), CFrame.new(0.5, 0.1, 0.1), Color3.fromRGB(120, 32, 74), Enum.Material.SmoothPlastic)
	ball(m, Vector3.new(0.55, 0.55, 0.55), CFrame.new(-0.42, 0.15, -0.12), Color3.fromRGB(168, 52, 104), Enum.Material.SmoothPlastic)
	ball(m, Vector3.new(0.5, 0.5, 0.5), CFrame.new(0.1, 0.5, -0.35), Color3.fromRGB(132, 36, 80), Enum.Material.SmoothPlastic)
	ball(m, Vector3.new(0.48, 0.48, 0.48), CFrame.new(-0.05, 0.45, 0.4), Color3.fromRGB(150, 40, 90), Enum.Material.SmoothPlastic)
	box(m, Vector3.new(0.5, 0.06, 0.22), CFrame.new(0.1, 0.75, -0.35) * CFrame.Angles(0, math.rad(20), math.rad(15)), Color3.fromRGB(90, 150, 70), Enum.Material.Grass)
	return root
end

function builders.Salt(m)
	local body = vcyl(m, 1.5, 1.0, CFrame.new(0, -0.2, 0), Color3.fromRGB(250, 250, 252), Enum.Material.Glass, { Transparency = 0.18 })
	vcyl(m, 0.45, 1.02, CFrame.new(0, 0.75, 0), Color3.fromRGB(120, 120, 132), Enum.Material.Metal)
	box(m, Vector3.new(0.7, 0.5, 0.02), CFrame.new(0, -0.25, 0.52), Color3.fromRGB(245, 245, 250), Enum.Material.SmoothPlastic)
	return body
end

function builders.Vanilla(m)
	local body = vcyl(m, 1.5, 0.8, CFrame.new(0, -0.2, 0), Color3.fromRGB(120, 70, 40), Enum.Material.Glass, { Transparency = 0.22 })
	vcyl(m, 0.5, 0.4, CFrame.new(0, 0.75, 0), Color3.fromRGB(110, 64, 36), Enum.Material.Glass, { Transparency = 0.22 })
	vcyl(m, 0.28, 0.42, CFrame.new(0, 1.05, 0), Color3.fromRGB(158, 116, 74), Enum.Material.Wood)
	box(m, Vector3.new(0.62, 0.7, 0.02), CFrame.new(0, -0.2, 0.42), Color3.fromRGB(240, 232, 214), Enum.Material.SmoothPlastic)
	return body
end

function builders.Cinnamon(m)
	local s1 = stick(m, 1.9, 0.32, CFrame.new(0, -0.1, 0.28) * CFrame.Angles(0, math.rad(6), 0), Color3.fromRGB(150, 96, 56), Enum.Material.Wood)
	stick(m, 1.9, 0.32, CFrame.new(0.05, 0.05, -0.05) * CFrame.Angles(0, math.rad(-4), 0), Color3.fromRGB(138, 86, 48), Enum.Material.Wood)
	stick(m, 1.8, 0.3, CFrame.new(-0.05, 0.22, -0.3) * CFrame.Angles(0, math.rad(10), 0), Color3.fromRGB(160, 104, 62), Enum.Material.Wood)
	box(m, Vector3.new(0.34, 0.55, 1.0), CFrame.new(0.1, 0.05, 0), Color3.fromRGB(120, 72, 44), Enum.Material.Fabric)
	return s1
end

function IngredientModels.build(ingredient: string): Model?
	local builder = builders[ingredient]
	if not builder then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = "Display_" .. ingredient
	local primary = builder(model)
	model.PrimaryPart = primary
	model:SetAttribute("BakerySpin", true)
	return model
end

return IngredientModels
