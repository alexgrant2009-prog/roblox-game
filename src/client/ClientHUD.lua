--!strict
-- ClientHUD
-- Everyone sees this: reputation, shift timer, score, and your role badge.
-- Also owns the lobby ready-up button, the toast feed, and the round summary.

local TweenService = game:GetService("TweenService")

local ClientHUD = {}
local remotes
local repLabel: TextLabel
local timerLabel: TextLabel
local scoreLabel: TextLabel
local roleBadge: TextLabel
local roleDesc: TextLabel
local dishLabel: TextLabel
local toastHolder: Frame
local lobbyFrame: Frame
local readyBtn: TextButton
local summaryFrame: Frame
local hasReadied = false

local ROLE_INFO = {
	Reader = { color = Color3.fromRGB(80, 130, 225), desc = "Read the tickets aloud. You can't touch the kitchen." },
	Cook = { color = Color3.fromRGB(230, 150, 70), desc = "Add ingredients & serve. You can't see the ticket." },
	Taster = { color = Color3.fromRGB(205, 90, 150), desc = "Taste the bowl for hints. You can't see the ticket." },
	Spectator = { color = Color3.fromRGB(120, 120, 130), desc = "Waiting for the next round..." },
}

local function fmtTime(secs: number): string
	secs = math.max(0, secs)
	return string.format("%d:%02d", math.floor(secs / 60), secs % 60)
end

function ClientHUD.init(player: Player, rem)
	remotes = rem

	local gui = Instance.new("ScreenGui")
	gui.Name = "BakeryHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")

	-- Top bar --------------------------------------------------------------
	local top = Instance.new("Frame")
	top.AnchorPoint = Vector2.new(0.5, 0)
	top.Position = UDim2.new(0.5, 0, 0, 10)
	top.Size = UDim2.new(0, 540, 0, 54)
	top.BackgroundColor3 = Color3.fromRGB(24, 22, 30)
	top.BackgroundTransparency = 0.1
	top.BorderSizePixel = 0
	local tc = Instance.new("UICorner")
	tc.CornerRadius = UDim.new(0, 12)
	tc.Parent = top
	top.Parent = gui

	local topLayout = Instance.new("UIListLayout")
	topLayout.FillDirection = Enum.FillDirection.Horizontal
	topLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	topLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	topLayout.Padding = UDim.new(0, 24)
	topLayout.Parent = top

	local function statLabel(order: number): TextLabel
		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(0, 160, 1, 0)
		l.BackgroundTransparency = 1
		l.Font = Enum.Font.GothamBold
		l.TextSize = 18
		l.TextColor3 = Color3.fromRGB(240, 240, 245)
		l.LayoutOrder = order
		l.Parent = top
		return l
	end

	repLabel = statLabel(1)
	repLabel.TextColor3 = Color3.fromRGB(230, 120, 120)
	timerLabel = statLabel(2)
	scoreLabel = statLabel(3)

	-- Role badge -----------------------------------------------------------
	local badge = Instance.new("Frame")
	badge.AnchorPoint = Vector2.new(0, 0)
	badge.Position = UDim2.new(0, 12, 0, 12)
	badge.Size = UDim2.new(0, 260, 0, 62)
	badge.BackgroundColor3 = Color3.fromRGB(40, 38, 46)
	badge.BackgroundTransparency = 0.1
	badge.BorderSizePixel = 0
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 10)
	bc.Parent = badge
	badge.Parent = gui

	roleBadge = Instance.new("TextLabel")
	roleBadge.Size = UDim2.new(1, -16, 0, 26)
	roleBadge.Position = UDim2.new(0, 8, 0, 6)
	roleBadge.BackgroundTransparency = 1
	roleBadge.Font = Enum.Font.GothamBold
	roleBadge.TextSize = 20
	roleBadge.TextXAlignment = Enum.TextXAlignment.Left
	roleBadge.Text = "..."
	roleBadge.Parent = badge

	roleDesc = Instance.new("TextLabel")
	roleDesc.Size = UDim2.new(1, -16, 0, 26)
	roleDesc.Position = UDim2.new(0, 8, 0, 30)
	roleDesc.BackgroundTransparency = 1
	roleDesc.Font = Enum.Font.Gotham
	roleDesc.TextSize = 12
	roleDesc.TextWrapped = true
	roleDesc.TextXAlignment = Enum.TextXAlignment.Left
	roleDesc.TextColor3 = Color3.fromRGB(190, 190, 200)
	roleDesc.Text = ""
	roleDesc.Parent = badge

	-- Cook's bowl counter (bottom-left; only meaningful info a Cook gets) ---
	dishLabel = Instance.new("TextLabel")
	dishLabel.AnchorPoint = Vector2.new(0, 1)
	dishLabel.Position = UDim2.new(0, 12, 1, -12)
	dishLabel.Size = UDim2.new(0, 220, 0, 30)
	dishLabel.BackgroundTransparency = 1
	dishLabel.Font = Enum.Font.GothamMedium
	dishLabel.TextSize = 16
	dishLabel.TextXAlignment = Enum.TextXAlignment.Left
	dishLabel.TextColor3 = Color3.fromRGB(210, 210, 220)
	dishLabel.Text = ""
	dishLabel.Parent = gui

	-- Toast feed (center, under top bar) -----------------------------------
	toastHolder = Instance.new("Frame")
	toastHolder.AnchorPoint = Vector2.new(0.5, 0)
	toastHolder.Position = UDim2.new(0.5, 0, 0, 74)
	toastHolder.Size = UDim2.new(0, 460, 0, 120)
	toastHolder.BackgroundTransparency = 1
	toastHolder.Parent = gui
	local toastLayout = Instance.new("UIListLayout")
	toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	toastLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	toastLayout.Padding = UDim.new(0, 4)
	toastLayout.Parent = toastHolder

	-- Lobby ready-up overlay ----------------------------------------------
	lobbyFrame = Instance.new("Frame")
	lobbyFrame.Size = UDim2.new(1, 0, 1, 0)
	lobbyFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
	lobbyFrame.BackgroundTransparency = 0.3
	lobbyFrame.BorderSizePixel = 0
	lobbyFrame.Visible = false
	lobbyFrame.Parent = gui

	local lobbyTitle = Instance.new("TextLabel")
	lobbyTitle.AnchorPoint = Vector2.new(0.5, 0.5)
	lobbyTitle.Position = UDim2.new(0.5, 0, 0.36, 0)
	lobbyTitle.Size = UDim2.new(0, 700, 0, 120)
	lobbyTitle.BackgroundTransparency = 1
	lobbyTitle.Font = Enum.Font.GothamBold
	lobbyTitle.TextSize = 52
	lobbyTitle.TextColor3 = Color3.fromRGB(255, 235, 190)
	lobbyTitle.Text = "BLACKOUT BAKERY"
	lobbyTitle.Parent = lobbyFrame

	local lobbySub = Instance.new("TextLabel")
	lobbySub.AnchorPoint = Vector2.new(0.5, 0.5)
	lobbySub.Position = UDim2.new(0.5, 0, 0.48, 0)
	lobbySub.Size = UDim2.new(0, 640, 0, 60)
	lobbySub.BackgroundTransparency = 1
	lobbySub.Font = Enum.Font.Gotham
	lobbySub.TextSize = 18
	lobbySub.TextWrapped = true
	lobbySub.TextColor3 = Color3.fromRGB(210, 210, 220)
	lobbySub.Text = "2-4 player co-op. One reads, one cooks, one tastes -- nobody has all the info. Roles rotate each round."
	lobbySub.Parent = lobbyFrame

	readyBtn = Instance.new("TextButton")
	readyBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	readyBtn.Position = UDim2.new(0.5, 0, 0.62, 0)
	readyBtn.Size = UDim2.new(0, 240, 0, 60)
	readyBtn.BackgroundColor3 = Color3.fromRGB(90, 180, 110)
	readyBtn.Font = Enum.Font.GothamBold
	readyBtn.TextSize = 24
	readyBtn.TextColor3 = Color3.new(1, 1, 1)
	readyBtn.Text = "READY UP"
	readyBtn.AutoButtonColor = true
	local rbc = Instance.new("UICorner")
	rbc.CornerRadius = UDim.new(0, 12)
	rbc.Parent = readyBtn
	readyBtn.Parent = lobbyFrame

	readyBtn.Activated:Connect(function()
		if hasReadied then
			return
		end
		hasReadied = true
		readyBtn.Text = "WAITING FOR OTHERS..."
		readyBtn.BackgroundColor3 = Color3.fromRGB(90, 100, 120)
		if remotes then
			remotes.Ready:FireServer()
		end
	end)

	-- Summary modal --------------------------------------------------------
	summaryFrame = Instance.new("Frame")
	summaryFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	summaryFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	summaryFrame.Size = UDim2.new(0, 460, 0, 260)
	summaryFrame.BackgroundColor3 = Color3.fromRGB(28, 26, 34)
	summaryFrame.BorderSizePixel = 0
	summaryFrame.Visible = false
	local sc = Instance.new("UICorner")
	sc.CornerRadius = UDim.new(0, 16)
	sc.Parent = summaryFrame
	summaryFrame.Parent = gui
end

local function pushToast(text: string, color: Color3)
	local toast = Instance.new("TextLabel")
	toast.Size = UDim2.new(1, 0, 0, 26)
	toast.BackgroundColor3 = Color3.fromRGB(20, 18, 26)
	toast.BackgroundTransparency = 0.15
	toast.Font = Enum.Font.GothamMedium
	toast.TextSize = 15
	toast.TextColor3 = color
	toast.Text = text
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = toast
	toast.Parent = toastHolder

	task.delay(3.5, function()
		local fade = TweenService:Create(toast, TweenInfo.new(0.5), {
			BackgroundTransparency = 1,
			TextTransparency = 1,
		})
		fade:Play()
		fade.Completed:Wait()
		toast:Destroy()
	end)
end

function ClientHUD.announce(msg)
	if typeof(msg) ~= "table" then
		return
	end
	if msg.kind == "summary" then
		ClientHUD.showSummary(msg)
		return
	end
	local palette = {
		good = Color3.fromRGB(140, 220, 140),
		bad = Color3.fromRGB(235, 120, 120),
		info = Color3.fromRGB(200, 200, 210),
		toast = Color3.fromRGB(220, 220, 230),
	}
	pushToast(msg.text or "", palette[msg.kind] or palette.toast)
end

function ClientHUD.setRole(role: string)
	local info = ROLE_INFO[role] or ROLE_INFO.Spectator
	roleBadge.Text = role
	roleBadge.TextColor3 = info.color
	roleDesc.Text = info.desc
end

function ClientHUD.showSummary(data)
	if not summaryFrame then
		return
	end
	for _, ch in ipairs(summaryFrame:GetChildren()) do
		if ch:IsA("TextLabel") then
			ch:Destroy()
		end
	end

	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, -20, 0, 50)
	header.Position = UDim2.new(0, 10, 0, 16)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.GothamBold
	header.TextSize = 30
	header.Text = data.failed and "SHIFT LOST" or "SHIFT COMPLETE"
	header.TextColor3 = data.failed and Color3.fromRGB(235, 110, 110) or Color3.fromRGB(140, 220, 140)
	header.Parent = summaryFrame

	local body = Instance.new("TextLabel")
	body.Size = UDim2.new(1, -40, 0, 150)
	body.Position = UDim2.new(0, 20, 0, 74)
	body.BackgroundTransparency = 1
	body.Font = Enum.Font.GothamMedium
	body.TextSize = 20
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextColor3 = Color3.fromRGB(230, 230, 235)
	body.Text = string.format(
		"Round %d of %d\n\nScore: %d\nPerfect dishes: %d",
		data.round or 0, data.roundsTotal or 0, data.score or 0, data.perfect or 0
	)
	body.Parent = summaryFrame

	summaryFrame.Visible = true
	task.delay(6.5, function()
		summaryFrame.Visible = false
	end)
end

function ClientHUD.update(data)
	if typeof(data) ~= "table" then
		return
	end

	repLabel.Text = "Rep " .. string.rep("♥", data.reputation or 0) .. string.rep("·", math.max(0, (data.maxReputation or 0) - (data.reputation or 0)))
	timerLabel.Text = "Time " .. fmtTime(data.timeLeft or 0)
	scoreLabel.Text = "Score " .. tostring(data.score or 0)

	-- Cook feedback: how many items are in the bowl (never what they should be).
	local n = data.dishTotal or 0
	dishLabel.Text = (data.phase == "ACTIVE") and ("Bowl: " .. n .. (n == 1 and " item" or " items")) or ""

	-- Lobby overlay visibility
	local inLobby = (data.phase == "LOBBY")
	if lobbyFrame.Visible ~= inLobby then
		lobbyFrame.Visible = inLobby
		if inLobby then
			hasReadied = false
			readyBtn.Text = "READY UP"
			readyBtn.BackgroundColor3 = Color3.fromRGB(90, 180, 110)
		end
	end
end

return ClientHUD
