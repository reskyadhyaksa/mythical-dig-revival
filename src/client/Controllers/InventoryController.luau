--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local packagesFolder = ReplicatedStorage:WaitForChild("Packages")
local Roact = require(packagesFolder:WaitForChild("Roact"))
local InventoryGui = require(script.Parent.Parent.Components.InventoryGui)
local Store = require(script.Parent.Parent.Rodux.Store)

local InventoryController = {}
local currentHandle: any = nil

function InventoryController.MountInventory(
	onSellItemCallback: ((itemId: string, amount: number) -> ())?,
	onSellAllCallback: (() -> ())?,
	onCloseCallback: (() -> ())?
)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local state = Store:getState()

	local element = Roact.createElement(InventoryGui, {
		Inventory = (state and state.Inventory) or {},
		Level = (state and state.Level) or 0,
		Coins = (state and state.Coins) or 0,
		OnClose = function()
			InventoryController.UnmountInventory()
			if onCloseCallback then
				onCloseCallback()
			end
		end,
		OnSellItem = onSellItemCallback,
		OnSellAll = onSellAllCallback,
	})

	if currentHandle then
		currentHandle = Roact.update(currentHandle, element)
	else
		currentHandle = Roact.mount(element, playerGui, "InventoryGuiUI")
	end
end

function InventoryController.UnmountInventory()
	if currentHandle then
		Roact.unmount(currentHandle)
		currentHandle = nil
	end
end

return InventoryController
