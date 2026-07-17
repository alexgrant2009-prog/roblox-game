--!strict
-- Bootstrap (Server entry point)
-- Wires the systems together and drives the game loop:
--   LOBBY (ready-up) -> COUNTDOWN -> ACTIVE shift -> SUMMARY -> rotate roles -> repeat
--
-- This is the orchestrator. It owns the shared `State` and a `ctx` table the
-- stateless systems reach back into (loseRep, announce, emitHud, ...).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("BlackoutBakery")
local GameConfig = require(Shared.GameConfig)
local Net = require(Shared.Net)
local SoundConfig = require(Shared.SoundConfig)

local serverFolder = script.Parent
local RoleManager = require(serverFolder.RoleManager)
local OrderManager = require(serverFolder.OrderManager)
local DishState = require(serverFolder.DishState)
local IngredientStation = require(serverFolder.IngredientStation)
local OvenStation = require(serverFolder.OvenStation)
local TasteService = require(serverFolder.TasteService)
local SubmitStation = require(serverFolder.SubmitStation)
local KitchenBuilder = require(serverFolder.KitchenBuilder)

local Remotes = Net.buildOnServer()

-- ---------------------------------------------------------------------------
-- Shared runtime state
-- ---------------------------------------------------------------------------
local State = {
	phase = "LOBBY", -- LOBBY | COUNTDOWN | ACTIVE | SUMMARY
	reputation = GameConfig.StartReputation,
	score = 0,
	perfect = 0,
	timeLeft = 0,
	round = 0,
	ready = {} :: { [Player]: boolean },
}

local Roles = RoleManager.new()
local Dish = DishState.new()

local ctx = {}
ctx.Config = GameConfig
ctx.Remotes = Remotes
ctx.Roles = Roles
ctx.Dish = Dish
ctx.TasteService = TasteService
ctx.State = State

local Orders = OrderManager.new(ctx)
ctx.Orders = Orders
ctx.getFrontRecipe = function()
	return Orders:frontRecipe()
end

-- ---------------------------------------------------------------------------
-- ctx helpers the systems call back into
-- ---------------------------------------------------------------------------
function ctx.announce(text: string, kind: string?)
	Remotes.Announce:FireAllClients({ kind = kind or "toast", text = text })
end

-- Sound helpers -------------------------------------------------------------
-- World sound: create a Sound on a part and play it server-side. This
-- replicates to clients, so everyone hears it positionally in the kitchen.
function ctx.sfxAt(part: BasePart?, name: string)
	local cfg = SoundConfig[name]
	if not (cfg and part) then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = cfg.id
	s.Volume = cfg.volume or 0.5
	s.PlaybackSpeed = cfg.speed or 1
	s.RollOffMinDistance = 8
	s.RollOffMaxDistance = 80
	s.Parent = part
	s:Play()
	Debris:AddItem(s, 6)
end

-- 2D UI sounds: tell clients to play a named sound locally.
function ctx.sfxAll(name: string)
	Remotes.Sfx:FireAllClients(name)
end
function ctx.sfxClient(player: Player, name: string)
	Remotes.Sfx:FireClient(player, name)
end

function ctx.emitHud()
	Remotes.Hud:FireAllClients({
		phase = State.phase,
		reputation = State.reputation,
		maxReputation = GameConfig.StartReputation,
		score = State.score,
		timeLeft = math.max(0, math.floor(State.timeLeft)),
		round = State.round,
		roundsTotal = GameConfig.RoundsPerSession,
		dishTotal = Dish.total, -- Cook feedback: how many things are in the bowl (never the recipe)
		dishBaked = Dish.baked,
		dishBaking = Dish.baking,
	})
end

function ctx.emitDishChanged()
	ctx.emitHud()
end

function ctx.loseRep(amount: number, reason: string?)
	State.reputation = math.max(0, State.reputation - amount)
	if reason then
		ctx.announce(reason, "bad")
	end
	ctx.emitHud()
end

-- ---------------------------------------------------------------------------
-- Build the kitchen and wire prompt triggers to the stations.
-- Role checks live inside the station handlers (server-authoritative).
-- ---------------------------------------------------------------------------
local kitchen = KitchenBuilder.build(ctx)
ctx.Kitchen = kitchen

for _, bin in ipairs(kitchen.bins) do
	bin.prompt.Triggered:Connect(function(player)
		IngredientStation.handleAdd(ctx, player, bin.ingredient)
	end)
end
kitchen.mixing.tastePrompt.Triggered:Connect(function(player)
	IngredientStation.handleTaste(ctx, player)
end)
kitchen.mixing.discardPrompt.Triggered:Connect(function(player)
	IngredientStation.handleDiscard(ctx, player)
end)
kitchen.oven.bakePrompt.Triggered:Connect(function(player)
	OvenStation.handleBake(ctx, player)
end)
kitchen.submit.servePrompt.Triggered:Connect(function(player)
	SubmitStation.handleServe(ctx, player)
end)

-- ---------------------------------------------------------------------------
-- Players
-- ---------------------------------------------------------------------------
local function currentPlayers(): { Player }
	return Players:GetPlayers()
end

local function broadcastRoles()
	for _, player in ipairs(currentPlayers()) do
		Remotes.Role:FireClient(player, Roles:getRole(player) or "Spectator")
	end
end

local function clearTickets()
	-- Wipe any lingering ticket the previous Reader had.
	for _, player in ipairs(currentPlayers()) do
		Remotes.Ticket:FireClient(player, {})
	end
end

Remotes.Ready.OnServerEvent:Connect(function(player)
	State.ready[player] = true
end)

Players.PlayerAdded:Connect(function(player)
	-- Late joiners spectate until the next assignment.
	Remotes.Role:FireClient(player, Roles:getRole(player) or "Spectator")
	ctx.emitHud()
end)

Players.PlayerRemoving:Connect(function(player)
	State.ready[player] = nil
end)

-- ---------------------------------------------------------------------------
-- Game loop
-- ---------------------------------------------------------------------------
local function waitForReady()
	State.phase = "LOBBY"
	ctx.emitHud()

	-- Need enough players first.
	while #currentPlayers() < GameConfig.MinPlayers do
		task.wait(1)
	end

	-- Then wait for everyone present to ready up (or the timeout).
	local waited = 0
	while true do
		local players = currentPlayers()
		if #players >= GameConfig.MinPlayers then
			local allReady = true
			for _, p in ipairs(players) do
				if not State.ready[p] then
					allReady = false
					break
				end
			end
			if allReady or waited >= GameConfig.ReadyTimeout then
				break
			end
			waited += 1
		else
			waited = 0
		end
		task.wait(1)
	end
end

local function runShift()
	-- Countdown
	State.phase = "COUNTDOWN"
	ctx.emitHud()
	for i = GameConfig.ReadyCountdown, 1, -1 do
		ctx.announce("Shift starts in " .. i .. "...", "info")
		ctx.sfxAll("CountdownTick")
		task.wait(1)
	end

	-- Active
	State.phase = "ACTIVE"
	State.reputation = GameConfig.StartReputation
	State.timeLeft = GameConfig.ShiftDuration
	Dish:clear()
	Orders:reset()
	Orders:refreshTicket()
	ctx.emitHud()
	ctx.sfxAll("ShiftStart")
	ctx.announce("Shift " .. State.round .. " -- get cooking!", "good")

	local elapsed = 0
	while State.timeLeft > 0 and State.reputation > 0 do
		local dt = task.wait(0.2)
		State.timeLeft -= dt
		elapsed += dt
		local frac = math.clamp(elapsed / GameConfig.ShiftDuration, 0, 1)
		Orders:update(dt, frac)
		ctx.emitHud()
	end

	-- Summary
	State.phase = "SUMMARY"
	local failed = State.reputation <= 0
	ctx.emitHud()
	ctx.sfxAll("ShiftEnd")
	Remotes.Announce:FireAllClients({
		kind = "summary",
		failed = failed,
		score = State.score,
		perfect = State.perfect,
		round = State.round,
		roundsTotal = GameConfig.RoundsPerSession,
	})
end

task.spawn(function()
	while true do
		State.ready = {}
		waitForReady()

		State.score = 0
		State.perfect = 0
		Roles:reset()

		for round = 1, GameConfig.RoundsPerSession do
			if #currentPlayers() < GameConfig.MinPlayers then
				break
			end
			State.round = round
			Roles:assign(currentPlayers())
			broadcastRoles()

			runShift()

			clearTickets()
			Roles:rotate()

			if round < GameConfig.RoundsPerSession and State.reputation > 0 then
				ctx.announce("Roles rotate -- next shift shortly!", "info")
			end
			task.wait(7) -- let the summary breathe
		end

		-- Back to the lobby for a fresh session.
		clearTickets()
		broadcastRoles()
	end
end)

print("[BlackoutBakery] Server ready.")
