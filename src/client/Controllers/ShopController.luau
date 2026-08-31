--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.Roact)
local ShopGui = require(script.Parent.Parent.Components.ShopGui)

local ShopController = {}
local currentHandle: any = nil

function ShopController.MountShop(coins: number, equippedShovel: string, ownedShovels: { string }, onBuyCallback: (shovelId: string) -> (), onEquipCallback: (shovelId: string) -> ())
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local element = Roact.createElement(ShopGui, {
		Coins = coins,
		EquippedShovel = equippedShovel,
		OwnedShovels = ownedShovels,
		OnClose = function()
			ShopController.UnmountShop()
		end,
		OnBuy = onBuyCallback,
		OnEquip = onEquipCallback,
	})

	if currentHandle then
		Roact.unmount(currentHandle)
	end

	currentHandle = Roact.mount(element, playerGui, "ShopGuiUI")
end

function ShopController.UnmountShop()
	if currentHandle then
		Roact.unmount(currentHandle)
		currentHandle = nil
	end
end

return ShopController
