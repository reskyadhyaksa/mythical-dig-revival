--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Roact = require(Packages.Roact)
local ShopGui = require(script.Parent.Parent.Components.ShopGui)

return function(target: Instance)
	local handle = Roact.mount(Roact.createElement(ShopGui, {
		Coins = 5000,
		EquippedShovel = "WoodenShovel",
		OwnedShovels = { "WoodenShovel" },
		OnClose = function()
			print("Storybook: Shop Closed")
		end,
		OnBuy = function(shovelId)
			print("Storybook: Bought Shovel", shovelId)
		end,
		OnEquip = function(shovelId)
			print("Storybook: Equipped Shovel", shovelId)
		end,
	}), target)

	return function()
		Roact.unmount(handle)
	end
end
