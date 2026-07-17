--!strict
-- ClientTicketUI
-- Renders the order tickets -- but ONLY if the Ticket event actually fired for
-- this client. Cooks and Tasters never receive that event, so this panel simply
-- never populates for them. There is no client-side "hide the frame" check;
-- there's nothing to hide, because the data never arrives.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("BlackoutBakery")
local RecipeConfig = require(Shared.RecipeConfig)

local ClientTicketUI = {}
local gui: ScreenGui
local listFrame: Frame

function ClientTicketUI.init(player: Player)
	gui = Instance.new("ScreenGui")
	gui.Name = "BakeryTicketUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Enabled = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(1, 0.5)
	panel.Position = UDim2.new(1, -16, 0.5, 0)
	panel.Size = UDim2.new(0, 300, 0, 540)
	panel.BackgroundColor3 = Color3.fromRGB(28, 26, 34)
	panel.BackgroundTransparency = 0.05
	panel.BorderSizePixel = 0
	panel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 46)
	title.BackgroundTransparency = 1
	title.Text = "ORDER TICKETS"
	title.TextColor3 = Color3.fromRGB(255, 235, 190)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 20
	title.Parent = panel

	listFrame = Instance.new("Frame")
	listFrame.Position = UDim2.new(0, 10, 0, 50)
	listFrame.Size = UDim2.new(1, -20, 1, -60)
	listFrame.BackgroundTransparency = 1
	listFrame.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = listFrame
end

local function ingredientText(recipe): string
	local parts = {}
	for ing, qty in pairs(recipe.ingredients) do
		local meta = RecipeConfig.Ingredients[ing]
		table.insert(parts, string.format("%dx %s", qty, meta and meta.display or ing))
	end
	table.sort(parts)
	return table.concat(parts, "\n")
end

function ClientTicketUI.render(queue)
	if not gui then
		return
	end
	for _, child in ipairs(listFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	if not queue or #queue == 0 then
		gui.Enabled = false
		return
	end
	gui.Enabled = true

	for i, order in ipairs(queue) do
		local recipe = RecipeConfig.getById(order.recipeId)
		if recipe then
			local isFront = (i == 1)

			local card = Instance.new("Frame")
			card.Size = UDim2.new(1, 0, 0, 98)
			card.BackgroundColor3 = isFront and Color3.fromRGB(60, 52, 40) or Color3.fromRGB(40, 38, 46)
			card.BorderSizePixel = 0
			card.LayoutOrder = i
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 8)
			c.Parent = card

			local name = Instance.new("TextLabel")
			name.Size = UDim2.new(1, -12, 0, 22)
			name.Position = UDim2.new(0, 8, 0, 4)
			name.BackgroundTransparency = 1
			name.TextXAlignment = Enum.TextXAlignment.Left
			name.Font = Enum.Font.GothamBold
			name.TextSize = 16
			name.TextColor3 = isFront and Color3.fromRGB(255, 220, 150) or Color3.fromRGB(220, 220, 230)
			name.Text = (isFront and "NOW: " or "") .. recipe.name
			name.Parent = card

			local ings = Instance.new("TextLabel")
			ings.Size = UDim2.new(1, -12, 0, 48)
			ings.Position = UDim2.new(0, 8, 0, 26)
			ings.BackgroundTransparency = 1
			ings.TextXAlignment = Enum.TextXAlignment.Left
			ings.TextYAlignment = Enum.TextYAlignment.Top
			ings.Font = Enum.Font.Gotham
			ings.TextSize = 13
			ings.TextColor3 = Color3.fromRGB(200, 200, 210)
			ings.Text = ingredientText(recipe)
			ings.Parent = card

			-- Patience bar
			local barBg = Instance.new("Frame")
			barBg.Size = UDim2.new(1, -16, 0, 6)
			barBg.Position = UDim2.new(0, 8, 1, -12)
			barBg.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
			barBg.BorderSizePixel = 0
			local bc = Instance.new("UICorner")
			bc.CornerRadius = UDim.new(1, 0)
			bc.Parent = barBg

			local frac = math.clamp(order.patience / math.max(1, order.patienceMax), 0, 1)
			local bar = Instance.new("Frame")
			bar.Size = UDim2.new(frac, 0, 1, 0)
			bar.BackgroundColor3 = (frac > 0.5 and Color3.fromRGB(120, 210, 120))
				or (frac > 0.25 and Color3.fromRGB(230, 200, 90) or Color3.fromRGB(230, 90, 90))
			bar.BorderSizePixel = 0
			local bc2 = Instance.new("UICorner")
			bc2.CornerRadius = UDim.new(1, 0)
			bc2.Parent = bar
			bar.Parent = barBg
			barBg.Parent = card

			card.Parent = listFrame
		end
	end
end

function ClientTicketUI.clear()
	if not gui then
		return
	end
	for _, child in ipairs(listFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	gui.Enabled = false
end

return ClientTicketUI
