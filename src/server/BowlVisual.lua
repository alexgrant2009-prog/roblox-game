--!strict
-- BowlVisual (Server)
-- Keeps a visible pile of ingredient bits inside the mixing bowl that mirrors
-- DishState. Rebuilt whenever the dish changes (hooked into emitDishChanged),
-- which only fires on real mutations -- not every HUD tick -- so it's cheap.
--
-- Raw   -> one small coloured bit per unit added.
-- Baked -> a single golden dome.
-- Burnt -> a charred lump.
--
-- This is shared (all clients see it). That's fine: what the Cook puts in the
-- bowl isn't secret -- they grab it in the open. Only the recipe is hidden.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BlackoutBakery")
local RecipeConfig = require(Shared.RecipeConfig)

local BowlVisual = {}

local bowlPart: BasePart? = nil
local container: Model? = nil

local GOLDEN = 2.399963 -- golden angle (radians) for an even pile

function BowlVisual.init(part: BasePart)
	bowlPart = part
	container = Instance.new("Model")
	container.Name = "BowlContents"
	container.Parent = part
end

local function bit(size: Vector3, pos: Vector3, color: Color3, material: Enum.Material, shape: Enum.PartType)
	local p = Instance.new("Part")
	p.Shape = shape
	p.Size = size
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Color = color
	p.Material = material
	p.Position = pos
	p.Parent = container
	return p
end

function BowlVisual.render(dish)
	if not (container and bowlPart) then
		return
	end
	container:ClearAllChildren()
	local center = bowlPart.Position

	if dish.burnt then
		bit(Vector3.new(3.8, 2.2, 3.8), center + Vector3.new(0, 1.0, 0),
			Color3.fromRGB(40, 33, 28), Enum.Material.Slate, Enum.PartType.Ball)
		bit(Vector3.new(2.6, 1.6, 2.6), center + Vector3.new(0.4, 1.7, -0.3),
			Color3.fromRGB(28, 24, 22), Enum.Material.Slate, Enum.PartType.Ball)
		return
	end

	if dish.baked then
		bit(Vector3.new(4.2, 2.6, 4.2), center + Vector3.new(0, 1.1, 0),
			Color3.fromRGB(206, 156, 96), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		bit(Vector3.new(2.4, 1.4, 2.4), center + Vector3.new(0, 2.1, 0),
			Color3.fromRGB(224, 178, 120), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		return
	end

	local total = math.max(1, dish.total)
	local idx = 0
	for _, ingName in ipairs(RecipeConfig.IngredientOrder) do
		local count = dish.ingredients[ingName]
		if count then
			local meta = RecipeConfig.Ingredients[ingName]
			for _ = 1, count do
				idx += 1
				local ang = idx * GOLDEN
				local rad = 2.0 * math.sqrt(idx / total)
				local px = math.cos(ang) * rad
				local pz = math.sin(ang) * rad
				local py = 0.85 + (idx % 3) * 0.22
				local s = 0.62 + (idx % 4) * 0.06
				bit(Vector3.new(s, s, s), center + Vector3.new(px, py, pz),
					meta.color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
			end
		end
	end
end

return BowlVisual
