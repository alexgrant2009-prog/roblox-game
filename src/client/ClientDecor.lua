--!strict
-- ClientDecor
-- Animates the floating ingredient displays (and anything else tagged with the
-- "BakerySpin" attribute): a gentle bob + slow spin. Purely cosmetic and done
-- locally with PivotTo, so it costs no network traffic and never fights the
-- server (the parts are anchored and the server never moves them).

local RunService = game:GetService("RunService")

local ClientDecor = {}

type Item = { model: Model, base: CFrame, phase: number }
local items: { Item } = {}

local function register(inst: Instance)
	if not inst:IsA("Model") then
		return
	end
	if inst:GetAttribute("BakerySpin") == nil then
		return
	end
	for _, it in ipairs(items) do
		if it.model == inst then
			return
		end
	end
	local ok, base = pcall(function()
		return inst:GetPivot()
	end)
	if ok then
		table.insert(items, { model = inst, base = base, phase = math.random() * math.pi * 2 })
	end
end

-- A one-shot ingredient bit that arcs from `from` to `to`, then vanishes.
function ClientDecor.toss(color: Color3, from: Vector3, to: Vector3)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(0.8, 0.8, 0.8)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.CFrame = CFrame.new(from)
	p.Parent = workspace

	local dur = 0.42
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local a = (os.clock() - t0) / dur
		if a >= 1 then
			conn:Disconnect()
			p:Destroy()
			return
		end
		local pos = from:Lerp(to, a) + Vector3.new(0, math.sin(a * math.pi) * 3.2, 0)
		p.CFrame = CFrame.new(pos) * CFrame.Angles(a * 9, a * 11, 0)
	end)
end

function ClientDecor.start()
	for _, inst in ipairs(workspace:GetDescendants()) do
		register(inst)
	end
	workspace.DescendantAdded:Connect(register)

	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for i = #items, 1, -1 do
			local it = items[i]
			if not it.model.Parent then
				table.remove(items, i)
			else
				local bob = math.sin(t * 2 + it.phase) * 0.35
				local angle = t * 1.1 + it.phase
				it.model:PivotTo((it.base + Vector3.new(0, bob, 0)) * CFrame.Angles(0, angle, 0))
			end
		end
	end)
end

return ClientDecor
