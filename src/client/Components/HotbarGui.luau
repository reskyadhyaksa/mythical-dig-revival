--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Roact = require(Packages.Roact)
local RoactRodux = require(Packages.RoactRodux)
local HotbarSlot = require(script.Parent.Common.HotbarSlot)

local HotbarGui = Roact.Component:extend("HotbarGui")

type ItemSlotData = {
	UUID: string?,
	ItemId: string,
	Count: number,
	Image: string?,
	FallbackEmoji: string?,
}

function HotbarGui:render()
	local isShovelEquipped = self.props.IsShovelEquipped or false
	local isInventoryOpen = self.props.IsInventoryOpen or false
	local isShopOpen = self.props.IsShopOpen or false
	local activeEquippedItem = self.props.ActiveEquippedItem or ""
	local activeEquippedUUID = self.props.ActiveEquippedUUID or ""

	local itemSlots: { ItemSlotData } = self.props.ItemSlots or {}

	local onToggleShovel = self.props.OnToggleShovel
	local onToggleInventory = self.props.OnToggleInventory
	local onToggleShop = self.props.OnToggleShop
	local onEquipItem = self.props.OnEquipItem

	local inventoryImage = "rbxassetid://81621266214171"
	local shopImage = "rbxassetid://131110815703277"

	-- Filter item slots valid (maksimal 4 item untuk slot 4 hingga 7)
	local validItemSlots: { ItemSlotData } = {}
	for _, itemData in ipairs(itemSlots) do
		if itemData.ItemId ~= "" and itemData.Count > 0 and #validItemSlots < 4 then
			table.insert(validItemSlots, itemData)
		end
	end

	local slotChildren: { [string]: any } = {
		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 16),
		}),

		UIStroke = Roact.createElement("UIStroke", {
			Color = Color3.fromRGB(60, 70, 90),
			Thickness = 1.5,
		}),

		UIListLayout = Roact.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			FillDirection = Enum.FillDirection.Horizontal,
		}),

		-- Slot 1: [1] Equip Shovel
		ShovelSlot = Roact.createElement(HotbarSlot, {
			LayoutOrder = 1,
			KeyText = "1",
			FallbackEmoji = "⚒️",
			IsActive = isShovelEquipped and activeEquippedItem == "",
			OnActivated = onToggleShovel,
		}),

		-- Slot 2: [2] Inventory
		InventorySlot = Roact.createElement(HotbarSlot, {
			LayoutOrder = 2,
			KeyText = "2",
			Image = inventoryImage,
			FallbackEmoji = "🎒",
			IsActive = isInventoryOpen,
			OnActivated = onToggleInventory,
		}),

		-- Slot 3: [3] Shop
		ShopSlot = Roact.createElement(HotbarSlot, {
			LayoutOrder = 3,
			KeyText = "3",
			Image = shopImage,
			FallbackEmoji = "🛒",
			IsActive = isShopOpen,
			OnActivated = onToggleShop,
		}),
	}

	-- Slots 4 hingga 7 (Muncul dinamis HANYA jika ada item di inventaris)
	for i, itemData in ipairs(validItemSlots) do
		local slotKey = tostring(i + 3) -- Key 4, 5, 6, 7
		local uuid = itemData.UUID or ""
		local itemId = itemData.ItemId
		local count = itemData.Count
		local image = itemData.Image or ""
		local fallbackEmoji = itemData.FallbackEmoji or "💎"

		-- Cek aktif berdasarkan UUID spesifik agar item lain dengan nama yang sama tidak ikut menyala!
		local isActive = if uuid ~= "" then (activeEquippedUUID == uuid) else (activeEquippedItem == itemId)

		slotChildren["ItemSlot_" .. slotKey] = Roact.createElement(HotbarSlot, {
			LayoutOrder = i + 3,
			KeyText = slotKey,
			Image = image,
			FallbackEmoji = fallbackEmoji,
			Count = count,
			IsActive = isActive,
			OnActivated = function()
				if onEquipItem then
					onEquipItem(uuid, itemId)
				end
			end,
		})
	end

	-- Hitung lebar kontainer responsif dinamis berdasarkan jumlah slot aktif
	local totalVisibleSlots = 3 + #validItemSlots
	local containerWidth = (totalVisibleSlots * 60) + ((totalVisibleSlots - 1) * 8) + 24

	return Roact.createElement("ScreenGui", {
		ResetOnSpawn = false,
		DisplayOrder = 10,
	}, {
		HotbarContainer = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -20),
			Size = UDim2.fromOffset(containerWidth, 76),
			BackgroundColor3 = Color3.fromRGB(18, 22, 32),
			BackgroundTransparency = 0.25,
			BorderSizePixel = 0,
		}, slotChildren),
	})
end

return RoactRodux.connect(function(state, props)
	return {
		ItemSlots = state.Inventory, -- Use inventory as item slots
	}
end)(HotbarGui)
