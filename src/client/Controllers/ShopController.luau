--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local packagesFolder = ReplicatedStorage:WaitForChild("Packages")
local Roact = require(packagesFolder:WaitForChild("Roact"))

local clientFolder = script.Parent.Parent
local componentsFolder = clientFolder:WaitForChild("Components")
local roduxFolder = clientFolder:WaitForChild("Rodux")
local Actions = require(roduxFolder:WaitForChild("Actions"))
local ShopGui = require(componentsFolder:WaitForChild("ShopGui"))
local Store = require(roduxFolder:WaitForChild("Store"))

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local buyShovelRE = remotesFolder:WaitForChild("BuyShovel") :: RemoteEvent
local equipShovelRE = remotesFolder:WaitForChild("EquipShovel") :: RemoteEvent
local getPlayerDataRF = remotesFolder:WaitForChild("GetPlayerData") :: RemoteFunction

local ShopController = {}
local currentHandle: any = nil
local isOpen = false

function ShopController.IsOpen(): boolean
	return isOpen
end

function ShopController.RefreshData()
	task.spawn(function()
		local updatedData = getPlayerDataRF:InvokeServer()
		if updatedData then
			Store:dispatch(Actions.SetPlayerData(updatedData))
		end
	end)
end

function ShopController.BuyShovel(shovelId: string)
	buyShovelRE:FireServer(shovelId)
	task.wait(0.1)
	ShopController.RefreshData()
end

function ShopController.EquipShovel(shovelId: string)
	equipShovelRE:FireServer(shovelId)
	task.wait(0.1)
	ShopController.RefreshData()
end

function ShopController.MountOrUpdate()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local state = Store:getState()

	local element = Roact.createElement(ShopGui, {
		Coins = (state and state.Coins) or 0,
		EquippedShovel = (state and state.EquippedShovel) or "WoodenShovel",
		OwnedShovels = (state and state.OwnedShovels) or { "WoodenShovel" },
		OnClose = function()
			ShopController.Close()
		end,
		OnBuy = function(shovelId)
			ShopController.BuyShovel(shovelId)
		end,
		OnEquip = function(shovelId)
			ShopController.EquipShovel(shovelId)
		end,
	})

	if currentHandle then
		currentHandle = Roact.update(currentHandle, element)
	else
		currentHandle = Roact.mount(element, playerGui, "ShopGuiUI")
	end
end

function ShopController.Open()
	local Controllers = clientFolder:WaitForChild("Controllers")
	local DigController = require(Controllers:WaitForChild("DigController")) :: any
	if DigController.IsMinigameActive() then
		return
	end

	local InventoryController = require(Controllers:WaitForChild("InventoryController")) :: any
	if InventoryController.IsOpen() then
		InventoryController.Close()
	end

	isOpen = true
	local HotbarController = require(Controllers:WaitForChild("HotbarController")) :: any
	HotbarController.SetState(nil, false, true)

	ShopController.RefreshData()
	ShopController.MountOrUpdate()
end

function ShopController.Close()
	isOpen = false
	local Controllers = clientFolder:WaitForChild("Controllers")
	local HotbarController = require(Controllers:WaitForChild("HotbarController")) :: any
	HotbarController.SetState(nil, false, false)

	if currentHandle then
		Roact.unmount(currentHandle)
		currentHandle = nil
	end
end

function ShopController.Toggle()
	if isOpen then
		ShopController.Close()
	else
		ShopController.Open()
	end
end

return ShopController
