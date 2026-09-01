--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Roact = require(Packages.Roact)
local DigMinigame = require(script.Parent.Parent.Components.DigMinigame)

return function(target: Instance)
	local handle = Roact.mount(
		Roact.createElement(DigMinigame, {
			CurrentHp = 50,
			MaxHp = 100,
			Rarity = "Legendary",
			ItemName = "Dragon Relic",
			MinDigPower = 15,
			ShovelPower = 25,
			IsTooWeak = false,
			TimeLimit = 30,
			OnSwing = function()
				print("Storybook: Swing Shovel Clicked!")
			end,
			OnCancel = function()
				print("Storybook: Dig Minigame Cancelled!")
			end,
		}),
		target
	)

	return function()
		Roact.unmount(handle)
	end
end
