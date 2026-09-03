--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local packagesFolder = ReplicatedStorage:WaitForChild("Packages")
local Roact = require(packagesFolder:WaitForChild("Roact"))
local clientFolder = script.Parent.Parent
local componentsFolder = clientFolder:WaitForChild("Components")
local roduxFolder = clientFolder:WaitForChild("Rodux")

local HotbarGui = require(componentsFolder:WaitForChild("HotbarGui"))
local Store = require(roduxFolder:WaitForChild("Store"))

local HotbarController = {}
local currentHandle: any = nil

local isShovelEquipped = false
local isInventoryOpen = false
local isShopOpen = false
local isAutoActive = false
local activeEquippedItem = ""
local activeEquippedUUID = ""

type ItemSlotData = {
	UUID: string?,
	ItemId: string,
	Count: number,
	Image: string?,
	FallbackEmoji: string?,
}

local onToggleShovelCb: (() -> ())? = nil
local onToggleInventoryCb: (() -> ())? = nil
local onToggleShopCb: (() -> ())? = nil
local onEquipItemCb: ((uuid: string, itemId: string) -> ())? = nil
local onToggleAutoCb: (() -> ())? = nil

local inputConnection: RBXScriptConnection? = nil

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

local function UpdateUI()
	if not currentHandle then return end

	local state = Store:getState()
	local currentInventory = (state and state.Inventory) or {}

	local element = Roact.createElement(HotbarGui, {
		IsShovelEquipped = isShovelEquipped,
		IsInventoryOpen = isInventoryOpen,
		IsShopOpen = isShopOpen,
		IsAutoActive = isAutoActive,
		ActiveEquippedItem = activeEquippedItem,
		ActiveEquippedUUID = activeEquippedUUID,
		ItemSlots = currentInventory,
		OnToggleShovel = onToggleShovelCb,
		OnToggleInventory = onToggleInventoryCb,
		OnToggleShop = onToggleShopCb,
		OnEquipItem = onEquipItemCb,
		OnToggleAuto = onToggleAutoCb,
	})

	currentHandle = Roact.update(currentHandle, element)
end

-- Sinkronisasi reaktif: Update Hotbar otomatis setiap kali data Store/Inventaris berubah
Store.changed:connect(function(_state)
	UpdateUI()
end)

function HotbarController.MountHotbar(
	onToggleShovel: () -> (),
	onToggleInventory: () -> (),
	onToggleShop: () -> (),
	onEquipItem: (uuid: string, itemId: string) -> (),
	onToggleAuto: (() -> ())?
)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	onToggleShovelCb = onToggleShovel
	onToggleInventoryCb = onToggleInventory
	onToggleShopCb = onToggleShop
	onEquipItemCb = onEquipItem
	onToggleAutoCb = onToggleAuto

	local state = Store:getState()
	local currentInventory = (state and state.Inventory) or {}

	local element = Roact.createElement(HotbarGui, {
		IsShovelEquipped = isShovelEquipped,
		IsInventoryOpen = isInventoryOpen,
		IsShopOpen = isShopOpen,
		IsAutoActive = isAutoActive,
		ActiveEquippedItem = activeEquippedItem,
		ActiveEquippedUUID = activeEquippedUUID,
		ItemSlots = currentInventory,
		OnToggleShovel = onToggleShovel,
		OnToggleInventory = onToggleInventory,
		OnToggleShop = onToggleShop,
		OnEquipItem = onEquipItem,
		OnToggleAuto = onToggleAuto,
	})

	if currentHandle then
		Roact.unmount(currentHandle)
	end

	currentHandle = Roact.mount(element, playerGui, "HotbarUI")

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
			local state = Store:getState()
			local currentInventory = (state and state.Inventory) or {}
			local itemData = currentInventory[itemIndex]
			if itemData and onEquipItemCb then
				local itemId = if typeof(itemData) == "table" then (itemData.ItemId or "") else tostring(itemData)
				local uuid = if typeof(itemData) == "table" then (itemData.UUID or "") else ""
				if itemId ~= "" then
					onEquipItemCb(uuid, itemId)
				end
			end
		end
	end)
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
		if equippedUUID ~= nil then
			activeEquippedUUID = equippedUUID
		elseif equippedItem == "" then
			activeEquippedUUID = ""
		end
		if equippedItem ~= "" then
			isShovelEquipped = false
		end
	end

	UpdateUI()
end

function HotbarController.SetInventory(newInventory: any)
	UpdateUI()
end

function HotbarController.SetAutoState(active: boolean)
	isAutoActive = active
	UpdateUI()
end

return HotbarController
