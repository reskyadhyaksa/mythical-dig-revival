--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.Roact)
local InventoryGui = require(script.Parent.Parent.Components.InventoryGui)

local InventoryController = {}
local currentHandle: any = nil

function InventoryController.MountInventory(inventory: { [string]: number }, level: number, coins: number, onSellItemCallback: (itemId: string, amount: number) -> (), onSellAllCallback: () -> ())
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local element = Roact.createElement(InventoryGui, {
		Inventory = inventory,
		Level = level,
		Coins = coins,
		OnClose = function()
			InventoryController.UnmountInventory()
		end,
		OnSellItem = onSellItemCallback,
		OnSellAll = onSellAllCallback,
	})

	if currentHandle then
		Roact.unmount(currentHandle)
	end

	currentHandle = Roact.mount(element, playerGui, "InventoryGuiUI")
end

function InventoryController.UnmountInventory()
	if currentHandle then
		Roact.unmount(currentHandle)
		currentHandle = nil
	end
end

return InventoryController
