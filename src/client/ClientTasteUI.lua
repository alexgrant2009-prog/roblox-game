--!strict
-- ClientTasteUI
-- Renders taste hints as a bubble near the bottom of the screen. Like the
-- ticket, this only ever shows content the server fired at THIS client -- only
-- the Taster is fired TasteHint events.

local TweenService = game:GetService("TweenService")

local ClientTasteUI = {}
local bubble: Frame
local textLabel: TextLabel
local hideToken = 0

function ClientTasteUI.init(player: Player)
	local gui = Instance.new("ScreenGui")
	gui.Name = "BakeryTasteUI"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	bubble = Instance.new("Frame")
	bubble.AnchorPoint = Vector2.new(0.5, 1)
	bubble.Position = UDim2.new(0.5, 0, 0.82, 0)
	bubble.Size = UDim2.new(0, 480, 0, 72)
	bubble.BackgroundColor3 = Color3.fromRGB(84, 40, 92)
	bubble.BackgroundTransparency = 1
	bubble.BorderSizePixel = 0
	bubble.Visible = false
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 14)
	c.Parent = bubble

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 54, 1, 0)
	icon.BackgroundTransparency = 1
	icon.Text = "TASTE"
	icon.Font = Enum.Font.GothamBold
	icon.TextSize = 14
	icon.TextColor3 = Color3.fromRGB(255, 200, 230)
	icon.Parent = bubble

	textLabel = Instance.new("TextLabel")
	textLabel.Position = UDim2.new(0, 60, 0, 0)
	textLabel.Size = UDim2.new(1, -72, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Color3.fromRGB(255, 240, 245)
	textLabel.TextTransparency = 1
	textLabel.Font = Enum.Font.GothamMedium
	textLabel.TextSize = 20
	textLabel.TextWrapped = true
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.Text = ""
	textLabel.Parent = bubble

	bubble.Parent = gui
end

function ClientTasteUI.show(hint: string)
	if not bubble then
		return
	end
	hideToken += 1
	local myToken = hideToken

	textLabel.Text = hint
	bubble.Visible = true
	TweenService:Create(bubble, TweenInfo.new(0.25), { BackgroundTransparency = 0.05 }):Play()
	TweenService:Create(textLabel, TweenInfo.new(0.25), { TextTransparency = 0 }):Play()

	task.delay(5, function()
		if myToken ~= hideToken then
			return
		end
		TweenService:Create(bubble, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
		local fade = TweenService:Create(textLabel, TweenInfo.new(0.4), { TextTransparency = 1 })
		fade:Play()
		fade.Completed:Wait()
		if myToken == hideToken then
			bubble.Visible = false
		end
	end)
end

function ClientTasteUI.clear()
	if bubble then
		hideToken += 1
		bubble.Visible = false
	end
end

return ClientTasteUI
