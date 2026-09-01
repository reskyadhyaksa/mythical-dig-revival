--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)
local HotbarGui = require(script.Parent.Parent.Components.HotbarGui)
local Store = require(script.Parent.Parent.Rodux.Store)

local HotbarController = {}
local currentHandle: any = nil

local isShovelEquipped = false
local isInventoryOpen = false
local isShopOpen = false
local activeEquippedItem = ""
local activeEquippedUUID = ""

type ItemSlotData = {
	UUID: string?,
	ItemId: string,
	Count: number,
	Image: string?,
	FallbackEmoji: string?,
}

local itemSlots: { ItemSlotData } = {}

local onToggleShovelCb: (() -> ())? = nil
local onToggleInventoryCb: (() -> ())? = nil
local onToggleShopCb: (() -> ())? = nil
local onEquipItemCb: ((uuid: string, itemId: string) -> ())? = nil

local inputConnection: RBXScriptConnection? = nil

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

local function UpdateUI()
	if not currentHandle then return end

	local app = Roact.createElement(RoactRodux.StoreProvider, {
		store = Store,
	}, {
		Hotbar = Roact.createElement(HotbarGui, {
			IsShovelEquipped = isShovelEquipped,
			IsInventoryOpen = isInventoryOpen,
			IsShopOpen = isShopOpen,
			ActiveEquippedItem = activeEquippedItem,
			ActiveEquippedUUID = activeEquippedUUID,
			ItemSlots = itemSlots,
			OnToggleShovel = onToggleShovelCb,
			OnToggleInventory = onToggleInventoryCb,
			OnToggleShop = onToggleShopCb,
			OnEquipItem = onEquipItemCb,
		}),
	})

	currentHandle = Roact.update(currentHandle, app)
end

function HotbarController.MountHotbar(
	onToggleShovel: () -> (),
	onToggleInventory: () -> (),
	onToggleShop: () -> (),
	onEquipItem: (uuid: string, itemId: string) -> ()
)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	onToggleShovelCb = onToggleShovel
	onToggleInventoryCb = onToggleInventory
	onToggleShopCb = onToggleShop
	onEquipItemCb = onEquipItem

	local app = Roact.createElement(RoactRodux.StoreProvider, {
		store = Store,
	}, {
		Hotbar = Roact.createElement(HotbarGui, {
			IsShovelEquipped = isShovelEquipped,
			IsInventoryOpen = isInventoryOpen,
			IsShopOpen = isShopOpen,
			ActiveEquippedItem = activeEquippedItem,
			ActiveEquippedUUID = activeEquippedUUID,
			ItemSlots = itemSlots,
			OnToggleShovel = onToggleShovel,
			OnToggleInventory = onToggleInventory,
			OnToggleShop = onToggleShop,
			OnEquipItem = onEquipItem,
		}),
	})

	if currentHandle then
		Roact.unmount(currentHandle)
	end

	currentHandle = Roact.mount(app, playerGui, "HotbarUI")

	if inputConnection then
		inputConnection:Disconnect()
	end

	inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		local keyCodes = {
			[Enum.KeyCode.One] = 1, [Enum.KeyCode.KeypadOne] = 1,
			[Enum.KeyCode.Two] = 2, [Enum.KeyCode.KeypadTwo] = 2,
			[Enum.KeyCode.Three] = 3, [Enum.KeyCode.KeypadThree] = 3,
			[Enum.KeyCode.Four] = 4, [Enum.KeyCode.KeypadFour] = 4,
			[Enum.KeyCode.Five] = 5, [Enum.KeyCode.KeypadFive] = 5,
			[Enum.KeyCode.Six] = 6, [Enum.KeyCode.KeypadSix] = 6,
			[Enum.KeyCode.Seven] = 7, [Enum.KeyCode.KeypadSeven] = 7,
			[Enum.KeyCode.Eight] = 8, [Enum.KeyCode.KeypadEight] = 8,
			[Enum.KeyCode.Nine] = 9, [Enum.KeyCode.KeypadNine] = 9,
		}

		local slotIndex = keyCodes[input.KeyCode]
		if not slotIndex then return end

		if slotIndex == 1 then
			if onToggleShovelCb then onToggleShovelCb() end
		elseif slotIndex == 2 then
			if onToggleInventoryCb then onToggleInventoryCb() end
		elseif slotIndex == 3 then
			if onToggleShopCb then onToggleShopCb() end
		else
			local itemIndex = slotIndex - 3
			local itemData = itemSlots[itemIndex]
			if itemData and itemData.ItemId ~= "" and onEquipItemCb then
				onEquipItemCb(itemData.UUID or "", itemData.ItemId)
			end
		end
	end)
end

function HotbarController.SetInventory(inventory: any)
	local slots: { ItemSlotData } = {}

	if typeof(inventory) == "table" then
		if #inventory > 0 then
			for index, item in ipairs(inventory) do
				if index <= 4 then
					local itemId = if typeof(item) == "table" then item.ItemId else item
					local uuid = if typeof(item) == "table" then item.UUID else ""
					table.insert(slots, {
						UUID = uuid,
						ItemId = itemId,
						Count = 1,
						FallbackEmoji = "💎",
					})
				end
			end
		else
			local index = 1
			for itemId, count in pairs(inventory) do
				if count > 0 and index <= 4 then
					table.insert(slots, {
						UUID = "",
						ItemId = itemId,
						Count = count,
						FallbackEmoji = "💎",
					})
					index += 1
				end
			end
		end
	end

	itemSlots = slots
	UpdateUI()
end

function HotbarController.SetState(
	shovelEquipped: boolean?,
	inventoryOpen: boolean?,
	shopOpen: boolean?,
	equippedItem: string?,
	equippedUUID: string?
)
	if shovelEquipped ~= nil then
		isShovelEquipped = shovelEquipped
		if shovelEquipped then
			activeEquippedItem = ""
			activeEquippedUUID = ""
		end
	end
	if inventoryOpen ~= nil then
		isInventoryOpen = inventoryOpen
	end
	if shopOpen ~= nil then
		isShopOpen = shopOpen
	end
	if equippedItem ~= nil then
		activeEquippedItem = equippedItem
		activeEquippedUUID = equippedUUID or ""
		if equippedItem ~= "" then
			isShovelEquipped = false
		end
	end

	UpdateUI()
end

return HotbarController
