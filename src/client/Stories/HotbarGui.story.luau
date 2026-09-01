--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Roact = require(Packages.Roact)
local HotbarGui = require(script.Parent.Parent.Components.HotbarGui)

return function(target: Instance)
	local handle = Roact.mount(Roact.createElement(HotbarGui, {
		IsShovelEquipped = true,
		IsInventoryOpen = false,
		IsShopOpen = false,
		ActiveEquippedItem = "",
		ItemSlots = {
			{ ItemId = "IronOre", Count = 5, FallbackEmoji = "🪨" },
			{ ItemId = "WyvernCore", Count = 1, FallbackEmoji = "🔮" },
		},
		OnToggleShovel = function()
			print("Storybook: Shovel Toggled")
		end,
		OnToggleInventory = function()
			print("Storybook: Inventory Toggled")
		end,
		OnToggleShop = function()
			print("Storybook: Shop Toggled")
		end,
		OnEquipItem = function(itemId)
			print("Storybook: Equip Item Clicked:", itemId)
		end,
	}), target)

	return function()
		Roact.unmount(handle)
	end
end
