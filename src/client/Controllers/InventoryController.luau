--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)
local InventoryGui = require(script.Parent.Parent.Components.InventoryGui)
local Store = require(script.Parent.Parent.Rodux.Store)

local InventoryController = {}
local currentHandle: any = nil

function InventoryController.MountInventory(
	onSellItemCallback: ((itemId: string, amount: number) -> ())?,
	onSellAllCallback: (() -> ())?,
	onCloseCallback: (() -> ())?
)
	onSellAllCallback: (() -> ())?,
	onCloseCallback: (() -> ())?
)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local app = Roact.createElement(RoactRodux.StoreProvider, {
		store = Store,
	}, {
		Inventory = Roact.createElement(InventoryGui, {
			OnClose = function()
				InventoryController.UnmountInventory()
				if onCloseCallback then
					onCloseCallback()
				end
			end,
			OnSellItem = onSellItemCallback,
			OnSellAll = onSellAllCallback,
		}),
	})

	if currentHandle then
		currentHandle = Roact.update(currentHandle, app)
	else
		currentHandle = Roact.mount(app, playerGui, "InventoryGuiUI")
	end
end

function InventoryController.UnmountInventory()
	if currentHandle then
		Roact.unmount(currentHandle)
		currentHandle = nil
	end
end

return InventoryController
