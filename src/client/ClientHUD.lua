--!strict
-- ClientHUD
-- Everyone sees this: reputation, shift timer, score, and your role badge.
-- Also owns the lobby ready-up button, the toast feed, and the round summary.

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local ClientHUD = {}
local remotes
local repLabel: TextLabel
local timerLabel: TextLabel
local scoreLabel: TextLabel
local roleBadge: TextLabel
local roleDesc: TextLabel
local streakLabel: TextLabel
local helpFrame: Frame
local helpHint: TextLabel
local helpPinned = false -- toggled with H
local dishLabel: TextLabel
local toastHolder: Frame
local lobbyFrame: Frame
local summaryFrame: Frame

local ROLE_INFO = {
	Reader = { color = Color3.fromRGB(80, 130, 225), desc = "Read the tickets aloud. You can't touch the kitchen." },
	Cook = { color = Color3.fromRGB(230, 150, 70), desc = "Add ingredients, bake & serve. You can't see the ticket." },
	Taster = { color = Color3.fromRGB(205, 90, 150), desc = "Taste the bowl for hints. You can't see the ticket." },
	Solo = { color = Color3.fromRGB(120, 220, 160), desc = "Solo test -- you can read, cook, and taste." },
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

	-- Combo streak badge (below the role badge; hidden until streak >= 2)
	streakLabel = Instance.new("TextLabel")
	streakLabel.AnchorPoint = Vector2.new(0, 0)
	streakLabel.Position = UDim2.new(0, 12, 0, 82)
	streakLabel.Size = UDim2.new(0, 260, 0, 34)
	streakLabel.BackgroundColor3 = Color3.fromRGB(60, 30, 20)
	streakLabel.BackgroundTransparency = 0.1
	streakLabel.Font = Enum.Font.GothamBold
	streakLabel.TextSize = 20
	streakLabel.TextColor3 = Color3.fromRGB(255, 180, 90)
	streakLabel.Text = ""
	streakLabel.Visible = false
	local strc = Instance.new("UICorner")
	strc.CornerRadius = UDim.new(0, 10)
	strc.Parent = streakLabel
	streakLabel.Parent = gui

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

	-- Lobby banner (non-blocking, so you can see and walk to the START pad) --
	lobbyFrame = Instance.new("Frame")
	lobbyFrame.AnchorPoint = Vector2.new(0.5, 0)
	lobbyFrame.Position = UDim2.new(0.5, 0, 0, 74)
	lobbyFrame.Size = UDim2.new(0, 560, 0, 96)
	lobbyFrame.BackgroundColor3 = Color3.fromRGB(24, 22, 30)
	lobbyFrame.BackgroundTransparency = 0.15
	lobbyFrame.BorderSizePixel = 0
	lobbyFrame.Visible = false
	local lbc = Instance.new("UICorner")
	lbc.CornerRadius = UDim.new(0, 12)
	lbc.Parent = lobbyFrame
	lobbyFrame.Parent = gui

	local lobbyTitle = Instance.new("TextLabel")
	lobbyTitle.Position = UDim2.new(0, 0, 0, 10)
	lobbyTitle.Size = UDim2.new(1, 0, 0, 40)
	lobbyTitle.BackgroundTransparency = 1
	lobbyTitle.Font = Enum.Font.GothamBold
	lobbyTitle.TextSize = 30
	lobbyTitle.TextColor3 = Color3.fromRGB(255, 235, 190)
	lobbyTitle.Text = "BLACKOUT BAKERY"
	lobbyTitle.Parent = lobbyFrame

	local lobbySub = Instance.new("TextLabel")
	lobbySub.Position = UDim2.new(0, 12, 0, 50)
	lobbySub.Size = UDim2.new(1, -24, 0, 38)
	lobbySub.BackgroundTransparency = 1
	lobbySub.Font = Enum.Font.GothamMedium
	lobbySub.TextSize = 17
	lobbySub.TextWrapped = true
	lobbySub.TextColor3 = Color3.fromRGB(150, 235, 170)
	lobbySub.Text = "Stand on the green ⭐ START pad with your team to begin."
	lobbySub.Parent = lobbyFrame

	-- Summary modal --------------------------------------------------------
	summaryFrame = Instance.new("Frame")
	summaryFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	summaryFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	summaryFrame.Size = UDim2.new(0, 460, 0, 320)
	summaryFrame.BackgroundColor3 = Color3.fromRGB(28, 26, 34)
	summaryFrame.BorderSizePixel = 0
	summaryFrame.Visible = false
	local sc = Instance.new("UICorner")
	sc.CornerRadius = UDim.new(0, 16)
	sc.Parent = summaryFrame
	summaryFrame.Parent = gui

	-- How-to-Play panel ----------------------------------------------------
	helpFrame = Instance.new("Frame")
	helpFrame.AnchorPoint = Vector2.new(0, 0.5)
	helpFrame.Position = UDim2.new(0, 16, 0.5, 20)
	helpFrame.Size = UDim2.new(0, 350, 0, 390)
	helpFrame.BackgroundColor3 = Color3.fromRGB(24, 22, 30)
	helpFrame.BackgroundTransparency = 0.08
	helpFrame.BorderSizePixel = 0
	helpFrame.Visible = false
	local hc = Instance.new("UICorner")
	hc.CornerRadius = UDim.new(0, 12)
	hc.Parent = helpFrame

	local hTitle = Instance.new("TextLabel")
	hTitle.Size = UDim2.new(1, -20, 0, 34)
	hTitle.Position = UDim2.new(0, 10, 0, 10)
	hTitle.BackgroundTransparency = 1
	hTitle.Font = Enum.Font.GothamBold
	hTitle.TextSize = 20
	hTitle.TextXAlignment = Enum.TextXAlignment.Left
	hTitle.TextColor3 = Color3.fromRGB(255, 235, 190)
	hTitle.Text = "HOW TO PLAY"
	hTitle.Parent = helpFrame

	local hBody = Instance.new("TextLabel")
	hBody.Size = UDim2.new(1, -28, 1, -54)
	hBody.Position = UDim2.new(0, 14, 0, 46)
	hBody.BackgroundTransparency = 1
	hBody.Font = Enum.Font.Gotham
	hBody.TextSize = 14
	hBody.TextXAlignment = Enum.TextXAlignment.Left
	hBody.TextYAlignment = Enum.TextYAlignment.Top
	hBody.TextWrapped = true
	hBody.TextColor3 = Color3.fromRGB(225, 225, 232)
	hBody.RichText = true
	hBody.Text = table.concat({
		"<b>1.</b> <font color='#ffd27a'>GRAB (E)</font> an ingredient at a bin — you carry it.",
		"<b>2.</b> Walk to the <b>Mixing Bowl</b> — it drops in.",
		"<b>3.</b> Repeat until the bowl matches the order.",
		"<b>4.</b> <font color='#ffd27a'>BAKE (R)</font> at the oven, then take it out on the green <font color='#8fdc8f'>READY!</font> window — don't let it burn.",
		"<b>5.</b> <font color='#ffd27a'>SERVE (F)</font> at the window.",
		"",
		"<font color='#ff9090'>Q</font> — scrap the bowl and start over.",
		"",
		"<b>Roles (they rotate each round):</b>",
		"<font color='#5a82e1'>Reader</font> — sees the ticket, tells the Cook.",
		"<font color='#e6963f'>Cook</font> — grabs, bakes, serves. No ticket.",
		"<font color='#cd5a96'>Taster</font> — tastes the bowl (E) for a hint.",
	}, "\n")
	hBody.Parent = helpFrame
	helpFrame.Parent = gui

	-- Persistent "[H] Help" hint (bottom-right)
	helpHint = Instance.new("TextLabel")
	helpHint.AnchorPoint = Vector2.new(1, 1)
	helpHint.Position = UDim2.new(1, -14, 1, -12)
	helpHint.Size = UDim2.new(0, 150, 0, 26)
	helpHint.BackgroundTransparency = 1
	helpHint.Font = Enum.Font.GothamMedium
	helpHint.TextSize = 15
	helpHint.TextXAlignment = Enum.TextXAlignment.Right
	helpHint.TextColor3 = Color3.fromRGB(200, 200, 210)
	helpHint.Text = "[H] How to play"
	helpHint.Parent = gui

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.H then
			helpPinned = not helpPinned
			helpFrame.Visible = helpPinned
		end
	end)
end

local function pushToast(text: string, color: Color3)
	-- Cap the feed so bursts (like the countdown) don't pile up.
	local existing = {}
	for _, ch in ipairs(toastHolder:GetChildren()) do
		if ch:IsA("TextLabel") then
			table.insert(existing, ch)
		end
	end
	if #existing >= 4 then
		existing[1]:Destroy()
	end

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

	task.delay(2.8, function()
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

	-- Star rating row
	local maxStars = data.maxStars or 3
	local stars = math.clamp(data.stars or 0, 0, maxStars)
	local starLabel = Instance.new("TextLabel")
	starLabel.Size = UDim2.new(1, -20, 0, 54)
	starLabel.Position = UDim2.new(0, 10, 0, 66)
	starLabel.BackgroundTransparency = 1
	starLabel.Font = Enum.Font.GothamBold
	starLabel.TextSize = 44
	starLabel.Text = string.rep("★", stars) .. string.rep("☆", maxStars - stars)
	starLabel.TextColor3 = (stars > 0) and Color3.fromRGB(255, 210, 90) or Color3.fromRGB(110, 105, 115)
	starLabel.Parent = summaryFrame

	local body = Instance.new("TextLabel")
	body.Size = UDim2.new(1, -40, 0, 150)
	body.Position = UDim2.new(0, 20, 0, 132)
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

	-- Combo streak badge
	local streak = data.streak or 0
	if streakLabel then
		if streak >= 2 and data.phase == "ACTIVE" then
			streakLabel.Visible = true
			streakLabel.Text = string.format("🔥 STREAK x%d", streak)
		else
			streakLabel.Visible = false
		end
	end

	-- Cook feedback: how many items are in the bowl (never what they should be),
	-- plus the bake state so the Cook knows to oven it before serving.
	if data.phase == "ACTIVE" then
		local n = data.dishTotal or 0
		local state, color
		if data.dishBurnt then
			state, color = "BURNT -- scrap it!", Color3.fromRGB(200, 90, 70)
		elseif data.dishBaking then
			state, color = "baking -- watch the oven!", Color3.fromRGB(255, 180, 90)
		elseif data.dishBaked then
			state, color = "baked -- serve it!", Color3.fromRGB(140, 220, 140)
		elseif n > 0 then
			state, color = "raw -- needs baking", Color3.fromRGB(220, 200, 120)
		else
			state, color = "empty", Color3.fromRGB(180, 180, 190)
		end
		dishLabel.Text = string.format("Bowl: %d %s  (%s)", n, (n == 1 and "item" or "items"), state)
		dishLabel.TextColor3 = color
	else
		dishLabel.Text = ""
	end

	-- Lobby banner visibility
	local inLobby = (data.phase == "LOBBY")
	lobbyFrame.Visible = inLobby

	-- How-to-Play: always up in the lobby; elsewhere it's the [H] toggle.
	if helpFrame then
		helpFrame.Visible = inLobby or helpPinned
	end
	if helpHint then
		helpHint.Visible = not inLobby
	end
end

return ClientHUD
