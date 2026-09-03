--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Roact = require(Packages.Roact)
local StatsHudGui = require(script.Parent.Parent.Components.StatsHudGui)

return function(target: Instance)
	local handle = Roact.mount(
		Roact.createElement(StatsHudGui, {
			Coins = 1_250_000,
			Luck = "+100%",
		}),
		target
	)

	return function()
		Roact.unmount(handle)
	end
end
