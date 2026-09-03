--!strict
local HotbarHelper = {}

export type ItemSlotData = {
	UUID: string?,
	ItemId: string,
	Count: number,
	Image: string?,
	FallbackEmoji: string?,
}

-- Filter item slots valid (maksimal 4 item untuk slot 4 hingga 7)
function HotbarHelper.FilterValidItemSlots(itemSlots: { any }?): { ItemSlotData }
	local validSlots: { ItemSlotData } = {}
	if not itemSlots then
		return validSlots
	end

	for _, itemData in ipairs(itemSlots) do
		local itemId = if typeof(itemData) == "table" then (itemData.ItemId or "") else tostring(itemData)
		local uuid = if typeof(itemData) == "table" then (itemData.UUID or "") else ""
		local count = if typeof(itemData) == "table" and itemData.Count then itemData.Count else 1
		local image = if typeof(itemData) == "table" and itemData.Image then itemData.Image else ""
		local fallbackEmoji = if typeof(itemData) == "table" and itemData.FallbackEmoji
			then itemData.FallbackEmoji
			else "💎"

		if itemId ~= "" and count > 0 and #validSlots < 4 then
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
