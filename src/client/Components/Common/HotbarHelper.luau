--!strict
local HotbarHelper = {}

export type ItemSlotData = {
	UUID: string?,
	ItemId: string,
	Count: number,
	Image: string?,
	FallbackEmoji: string?,
}

-- Default kapasitas slot item dinamis pada Hotbar (Slot 4 dst.)
HotbarHelper.DEFAULT_MAX_ITEM_SLOTS = 4

-- Filter item slots valid dengan batas slot yang dapat dikonfigurasi
function HotbarHelper.FilterValidItemSlots(itemSlots: { any }?, maxSlots: number?): { ItemSlotData }
	local validSlots: { ItemSlotData } = {}
	if not itemSlots then
		return validSlots
	end

	local maxCount = maxSlots or HotbarHelper.DEFAULT_MAX_ITEM_SLOTS

	for _, itemData in ipairs(itemSlots) do
		local itemId = if typeof(itemData) == "table" then (itemData.ItemId or "") else tostring(itemData)
		local uuid = if typeof(itemData) == "table" then (itemData.UUID or "") else ""
		local count = if typeof(itemData) == "table" and itemData.Count then itemData.Count else 1
		local image = if typeof(itemData) == "table" and itemData.Image then itemData.Image else ""
		local fallbackEmoji = if typeof(itemData) == "table" and itemData.FallbackEmoji
			then itemData.FallbackEmoji
			else "💎"

		if itemId ~= "" and count > 0 and #validSlots < maxCount then
			table.insert(validSlots, {
				UUID = uuid,
				ItemId = itemId,
				Count = count,
				Image = image,
				FallbackEmoji = fallbackEmoji,
			})
		end
	end

	return validSlots
end

-- Menentukan apakah slot item aktif / sedang di-equip
function HotbarHelper.IsSlotActive(
	activeEquippedUUID: string,
	activeEquippedItem: string,
	slotUUID: string,
	slotItemId: string,
	index: number
): boolean
	if activeEquippedUUID ~= "" and slotUUID ~= "" then
		return activeEquippedUUID == slotUUID
	elseif activeEquippedUUID == "" and activeEquippedItem ~= "" then
		return activeEquippedItem == slotItemId and index == 1
	end
	return false
end

-- Menghitung lebar wrapper Hotbar berbasis Scale
function HotbarHelper.CalculateWrapperWidth(totalVisibleSlots: number): number
	return math.clamp(0.065 * totalVisibleSlots + 0.02, 0.20, 0.60)
end

return HotbarHelper
