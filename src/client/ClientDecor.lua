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
