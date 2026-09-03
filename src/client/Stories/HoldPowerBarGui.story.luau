--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Packages = ReplicatedStorage.Packages
local Roact = require(Packages.Roact)
local HoldPowerBarGui = require(script.Parent.Parent.Components.HoldPowerBarGui)

return function(target: Instance)
	local progress = 0
	local multiplier = 1.0

	local handle = Roact.mount(
		Roact.createElement(HoldPowerBarGui, {
			Visible = true,
			Progress = 0.5,
			Multiplier = 1.5,
		}),
		target
	)

	local timeElapsed = 0
	local connection = RunService.RenderStepped:Connect(function(dt)
		timeElapsed += dt
		progress = (math.sin(timeElapsed * 3) + 1) / 2
		multiplier = 1.0 + (progress * 1.5)

		Roact.update(
			handle,
			Roact.createElement(HoldPowerBarGui, {
				Visible = true,
				Progress = progress,
				Multiplier = multiplier,
			})
		)
	end)

	return function()
		connection:Disconnect()
		Roact.unmount(handle)
	end
end
