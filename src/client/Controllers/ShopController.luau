--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local packagesFolder = ReplicatedStorage:WaitForChild("Packages")
local Roact = require(packagesFolder:WaitForChild("Roact"))
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
	local state = Store:getState()

	local element = Roact.createElement(ShopGui, {
		Coins = (state and state.Coins) or 0,
		EquippedShovel = (state and state.EquippedShovel) or "WoodenShovel",
		OwnedShovels = (state and state.OwnedShovels) or { "WoodenShovel" },
		OnClose = function()
			ShopController.UnmountShop()
			if onCloseCallback then
				onCloseCallback()
			end
		end,
		OnBuy = onBuyCallback,
		OnEquip = onEquipCallback,
	})

	if currentHandle then
		currentHandle = Roact.update(currentHandle, element)
	else
		currentHandle = Roact.mount(element, playerGui, "ShopGuiUI")
	end
end

function ShopController.UnmountShop()
	if currentHandle then
		Roact.unmount(currentHandle)
		currentHandle = nil
	end
end

return ShopController
