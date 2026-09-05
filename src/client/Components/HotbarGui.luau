--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local DeviceHelper = require(ReplicatedStorage.Shared.Common.DeviceHelper)
local Roact = require(Packages:WaitForChild("Roact"))

local Common = script.Parent.Common
local HotbarSlot = require(Common.HotbarSlot)
local AutoButton = require(Common.AutoButton)
local HotbarHelper = require(Common.HotbarHelper)

export type ItemSlotData = HotbarHelper.ItemSlotData

local ASSET_IMAGES = {
	Shovel = "rbxassetid://89491227108779",
	Inventory = "rbxassetid://103164704580526",
	Shop = "rbxassetid://90299548253286",
}

local HotbarGui = Roact.Component:extend("HotbarGui")
local deviceType = DeviceHelper.GetDeviceType()

function HotbarGui:render()
	local isShovelEquipped = self.props.IsShovelEquipped or false
	local isInventoryOpen = self.props.IsInventoryOpen or false
	local isShopOpen = self.props.IsShopOpen or false
	local activeEquippedItem = self.props.ActiveEquippedItem or ""
	local activeEquippedUUID = self.props.ActiveEquippedUUID or ""
	local isAutoActive = self.props.IsAutoActive or false

	local onToggleShovel = self.props.OnToggleShovel
	local onToggleInventory = self.props.OnToggleInventory
	local onToggleShop = self.props.OnToggleShop
	local onEquipItem = self.props.OnEquipItem
	local onToggleAuto = self.props.OnToggleAuto

	local maxItemSlots = self.props.MaxItemSlots
	local validItemSlots = HotbarHelper.FilterValidItemSlots(self.props.ItemSlots, maxItemSlots)
	local totalVisibleSlots = 3 + #validItemSlots
	local wrapperWidthScale = HotbarHelper.CalculateWrapperWidth(totalVisibleSlots)
	local wrapperHeightScale = if deviceType == "Mobile" then 0.125 else 0.095
	local listGap = if deviceType == "Mobile" then UDim.new(0.06, 0) else UDim.new(0.05, 0)

	local slotChildren: { [string]: any } = {
		UIListLayout = Roact.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = listGap,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			FillDirection = Enum.FillDirection.Horizontal,
		}),

		-- Slot 1: [1] Equip Shovel
		ShovelSlot = Roact.createElement(HotbarSlot, {
			LayoutOrder = 1,
			KeyText = "1",
			Image = ASSET_IMAGES.Shovel,
			FallbackEmoji = "⚒️",
			IsActive = isShovelEquipped and activeEquippedItem == "",
			OnActivated = onToggleShovel,
			Size = UDim2.fromScale(1, 1),
		}),

		-- Slot 2: [2] Inventory
		InventorySlot = Roact.createElement(HotbarSlot, {
			LayoutOrder = 2,
			KeyText = "2",
			Image = ASSET_IMAGES.Inventory,
			FallbackEmoji = "🎒",
			IsActive = isInventoryOpen,
			OnActivated = onToggleInventory,
			Size = UDim2.fromScale(1, 1),
			IconSize = UDim2.fromScale(0.72, 0.72),
		}),

		-- Slot 3: [3] Shop
		ShopSlot = Roact.createElement(HotbarSlot, {
			LayoutOrder = 3,
			KeyText = "3",
			Image = ASSET_IMAGES.Shop,
			FallbackEmoji = "🛒",
			IsActive = isShopOpen,
			OnActivated = onToggleShop,
			Size = UDim2.fromScale(1, 1),
			IconSize = UDim2.fromScale(0.68, 0.68),
		}),
	}

	-- Slots 4 hingga 7 (Muncul dinamis HANYA jika ada item di inventaris)
	for i, itemData in ipairs(validItemSlots) do
		local slotKey = tostring(i + 3)
		local uuid = itemData.UUID or ""
		local itemId = itemData.ItemId
		local isActive = HotbarHelper.IsSlotActive(activeEquippedUUID, activeEquippedItem, uuid, itemId, i)

		slotChildren["ItemSlot_" .. slotKey] = Roact.createElement(HotbarSlot, {
			LayoutOrder = i + 3,
			KeyText = slotKey,
			Image = itemData.Image or "",
			FallbackEmoji = itemData.FallbackEmoji or "💎",
			Count = itemData.Count,
			IsActive = isActive,
			Size = UDim2.fromScale(1, 1),
			OnActivated = function()
				if onEquipItem then
					onEquipItem(uuid, itemId)
				end
			end,
		})
	end

	return Roact.createElement("ScreenGui", {
		ResetOnSpawn = false,
		DisplayOrder = 10,
	}, {
		AutoButton = Roact.createElement(AutoButton, {
			IsActive = isAutoActive,
			OnToggle = onToggleAuto,
			-- Position = UDim2.fromScale(0.5, 0.86),
			Position = if deviceType == "Mobile" then UDim2.fromScale(0.5, 0.81) else UDim2.fromScale(0.5, 0.86),
			Size = if deviceType == "Mobile" then UDim2.fromScale(0.1, 0.07) else UDim2.fromScale(0.12, 0.045),
		}),

		HotbarWrapper = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.98),
			-- Size = UDim2.fromScale(wrapperWidthScale, 0.095),
			Size = UDim2.fromScale(wrapperWidthScale, wrapperHeightScale),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, slotChildren),
	})
end

return HotbarGui
