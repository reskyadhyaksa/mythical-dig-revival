--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)
local ShopGui = require(script.Parent.Parent.Components.ShopGui)
local Store = require(script.Parent.Parent.Rodux.Store)

local ShopController = {}
local currentHandle: any = nil

function ShopController.MountShop(
	onBuyCallback: ((shovelId: string) -> ())?,
	onEquipCallback: ((shovelId: string) -> ())?,
	onCloseCallback: (() -> ())?
)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local app = Roact.createElement(RoactRodux.StoreProvider, {
		store = Store,
	}, {
		Shop = Roact.createElement(ShopGui, {
			OnClose = function()
				ShopController.UnmountShop()
				if onCloseCallback then
					onCloseCallback()
				end
			end,
			OnBuy = onBuyCallback,
			OnEquip = onEquipCallback,
		}),
	})

	if currentHandle then
		currentHandle = Roact.update(currentHandle, app)
	else
		currentHandle = Roact.mount(app, playerGui, "ShopGuiUI")
	end
end

function ShopController.UnmountShop()
	if currentHandle then
		Roact.unmount(currentHandle)
		currentHandle = nil
	end
end

return ShopController
