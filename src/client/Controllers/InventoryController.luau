--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local packagesFolder = ReplicatedStorage:WaitForChild("Packages")
local Roact = require(packagesFolder:WaitForChild("Roact"))

local clientFolder = script.Parent.Parent
local componentsFolder = clientFolder:WaitForChild("Components")
local roduxFolder = clientFolder:WaitForChild("Rodux")
local Actions = require(roduxFolder:WaitForChild("Actions"))
local InventoryGui = require(componentsFolder:WaitForChild("InventoryGui"))
local Store = require(roduxFolder:WaitForChild("Store"))

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local sellItemRE = remotesFolder:WaitForChild("SellItem") :: RemoteEvent
local sellAllRE = remotesFolder:WaitForChild("SellAll") :: RemoteEvent
local getPlayerDataRF = remotesFolder:WaitForChild("GetPlayerData") :: RemoteFunction

local InventoryController = {}
local currentHandle: any = nil
local isOpen = false

function InventoryController.IsOpen(): boolean
	return isOpen
end

function InventoryController.RefreshData()
	task.spawn(function()
		local updatedData = getPlayerDataRF:InvokeServer()
		if updatedData then
			Store:dispatch(Actions.SetPlayerData(updatedData))
		end
	end)
end

function InventoryController.SellItem(uuidOrItemId: string, amount: number)
	sellItemRE:FireServer(uuidOrItemId, amount)
	task.wait(0.1)
	InventoryController.RefreshData()
end

function InventoryController.SellAll()
	sellAllRE:FireServer()
	task.wait(0.1)
	InventoryController.RefreshData()
end

function InventoryController.MountOrUpdate()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local state = Store:getState()

	local element = Roact.createElement(InventoryGui, {
		Inventory = (state and state.Inventory) or {},
		Level = (state and state.Level) or 0,
		Coins = (state and state.Coins) or 0,
		OnClose = function()
			InventoryController.Close()
		end,
		OnSellItem = function(uuidOrItemId, amount)
			InventoryController.SellItem(uuidOrItemId, amount)
		end,
		OnSellAll = function()
			InventoryController.SellAll()
		end,
	})

	if currentHandle then
		currentHandle = Roact.update(currentHandle, element)
	else
		currentHandle = Roact.mount(element, playerGui, "InventoryGuiUI")
	end
end

function InventoryController.Open()
	local Controllers = clientFolder:WaitForChild("Controllers")
	local DigController = require(Controllers:WaitForChild("DigController")) :: any
	if DigController.IsMinigameActive() then
		return
	end

	local ShopController = require(Controllers:WaitForChild("ShopController")) :: any
	if ShopController.IsOpen() then
		ShopController.Close()
	end

	isOpen = true
	local HotbarController = require(Controllers:WaitForChild("HotbarController")) :: any
	HotbarController.SetState(nil, true, false)

	InventoryController.RefreshData()
	InventoryController.MountOrUpdate()
end

function InventoryController.Close()
	isOpen = false
	local Controllers = clientFolder:WaitForChild("Controllers")
	local HotbarController = require(Controllers:WaitForChild("HotbarController")) :: any
	HotbarController.SetState(nil, false, false)

	if currentHandle then
		Roact.unmount(currentHandle)
		currentHandle = nil
	end
end

function InventoryController.Toggle()
	if isOpen then
		InventoryController.Close()
	else
		InventoryController.Open()
	end
end

return InventoryController
