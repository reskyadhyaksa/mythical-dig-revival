--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Roact = require(Packages.Roact)
local InventoryGui = require(script.Parent.Parent.Components.InventoryGui)

return function(target: Instance)
	local handle = Roact.mount(Roact.createElement(InventoryGui, {
		Inventory = {
			["GrassChunk"] = 5,
			["AncientCoin"] = 2,
			["DragonRelic"] = 1,
		},
		Level = 5,
		Coins = 2500,
		OnClose = function()
			print("Storybook: Inventory Closed")
		end,
		OnSellItem = function(itemId, amount)
			print("Storybook: Sold Item", itemId, amount)
		end,
		OnSellAll = function()
			print("Storybook: Sold All Items")
		end,
	}), target)

	return function()
		Roact.unmount(handle)
	end
end
