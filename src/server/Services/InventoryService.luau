--!strict
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = ReplicatedStorage:FindFirstChild("Assets")
local Items = require(ReplicatedStorage.Shared.Data.Items) :: any

export type InventoryItem = {
	UUID: string,
	ItemId: string,
	Weight: number,
}

local InventoryService = {}

function InventoryService.GetTotalItemCount(inventory: { any }?): number
	if not inventory then
		return 0
	end
	return #inventory
end

function InventoryService.GetTotalInventoryWeight(inventory: { any }?): number
	if not inventory then
		return 0
	end

	local totalWeight = 0
	for _, item in ipairs(inventory) do
		if typeof(item) == "table" and item.Weight then
			totalWeight += item.Weight
		elseif typeof(item) == "table" and item.ItemId then
			totalWeight += Items.GetItemWeight(item.ItemId)
		end
	end

	return totalWeight
end

function InventoryService.AddItem(playerProfile: any, itemId: string, customWeight: number?): InventoryItem?
	if not playerProfile or not playerProfile.Data then
		return nil
	end

	if typeof(playerProfile.Data.Inventory) ~= "table" then
		playerProfile.Data.Inventory = {}
	end

	local uuid = HttpService:GenerateGUID(false)
	local weight = customWeight or Items.GetItemWeight(itemId)

	local newItem: InventoryItem = {
		UUID = uuid,
		ItemId = itemId,
		Weight = weight,
	}

	table.insert(playerProfile.Data.Inventory, newItem)
	print(string.format("🎒 Item added! Name: %s | UUID: %s | Weight: %.1fkg", itemId, uuid, weight))

	return newItem
end

function InventoryService.AutoWeldTool(tool: Tool)
	local handle = tool:FindFirstChild("Handle") :: BasePart?
	if not handle then
		local altPart = tool:FindFirstChildWhichIsA("BasePart", true)
		if altPart then
			altPart.Name = "Handle"
			handle = altPart
		end
	end

	if not handle then
		return
	end

	handle.Anchored = false
	handle.CanCollide = false

	for _, descendant in tool:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false

			if descendant ~= handle then
				local existingWeld = descendant:FindFirstChildOfClass("WeldConstraint") or descendant:FindFirstChildOfClass("Weld")
				if not existingWeld then
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = handle
					weld.Part1 = descendant
					weld.Parent = descendant
				end
			end
		end
	end
end

function InventoryService.GiveShovelToBackpack(player: Player, shovelId: string)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end

	-- Hapus sekop lama hanya di dalam Backpack
	for _, child in backpack:GetChildren() do
		if child:IsA("Tool") then
			child:Destroy()
		end
	end

	if not Assets then
		return
	end

	local shovelsFolder = Assets:FindFirstChild("Shovels")
	if not shovelsFolder then
		return
	end

	local shovelTemplate = shovelsFolder:FindFirstChild(shovelId)
	if shovelTemplate then
		local shovelClone = shovelTemplate:Clone()
		if shovelClone:IsA("Tool") then
			InventoryService.AutoWeldTool(shovelClone)
			shovelClone.Parent = backpack
		end
	end
end

function InventoryService.EquipShovelModel(character: Model, shovelId: string)
	local Players = game:GetService("Players")
	local player = Players:GetPlayerFromCharacter(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local backpack = player and player:FindFirstChildOfClass("Backpack")

	for _, child in character:GetChildren() do
		if child:IsA("Tool") then
			child:Destroy()
		end
	end

	if backpack then
		for _, child in backpack:GetChildren() do
			if child:IsA("Tool") then
				child:Destroy()
			end
		end
	end

	if not Assets then
		return
	end

	local shovelsFolder = Assets:FindFirstChild("Shovels")
	if not shovelsFolder then
		return
	end

	local shovelTemplate = shovelsFolder:FindFirstChild(shovelId)
	if shovelTemplate then
		local shovelClone = shovelTemplate:Clone()
		if shovelClone:IsA("Tool") then
			InventoryService.AutoWeldTool(shovelClone)
		end

		if backpack and humanoid then
			shovelClone.Parent = backpack
			humanoid:EquipTool(shovelClone)
		else
			shovelClone.Parent = character
		end
	end
end

-- Equip Item dari ReplicatedStorage.Assets.Items dengan Skala Ukuran Berdasarkan Weight
function InventoryService.EquipItemModel(character: Model, itemId: string)
	local Players = game:GetService("Players")
	local player = Players:GetPlayerFromCharacter(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local backpack = player and player:FindFirstChildOfClass("Backpack")

	for _, child in character:GetChildren() do
		if child:IsA("Tool") then
			child:Destroy()
		end
	end

	if backpack then
		for _, child in backpack:GetChildren() do
			if child:IsA("Tool") then
				child:Destroy()
			end
		end
	end

	local itemTool: Tool? = nil
	local weight = Items.GetItemWeight(itemId)
	-- Formula Skala Ukuran: Semakin besar Weight, semakin besar ukuran visual item yang dipegang!
	local scaleFactor = math.clamp(0.8 + (weight ^ 0.35) * 0.25, 0.7, 3.5)

	if Assets then
		local itemsFolder = Assets:FindFirstChild("Items")
		local itemTemplate = itemsFolder and itemsFolder:FindFirstChild(itemId)
		if itemTemplate then
			local newTool = Instance.new("Tool")
			newTool.Name = itemId

			local clone = itemTemplate:Clone()
			clone.Parent = newTool

			if clone:IsA("Model") then
				clone:ScaleTo(scaleFactor)
				local primary = clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart", true)
				if primary then
					primary.Name = "Handle"
				end
			elseif clone:IsA("BasePart") then
				clone.Size = clone.Size * scaleFactor
				clone.Name = "Handle"
			end

			itemTool = newTool
		end
	end

	if not itemTool then
		-- Fallback visual jika template belum ada di ReplicatedStorage.Assets.Items
		local newTool = Instance.new("Tool")
		newTool.Name = itemId
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(1, 1, 1) * scaleFactor
		handle.Color = Color3.fromRGB(241, 196, 15)
		handle.Material = Enum.Material.SmoothPlastic
		handle.Parent = newTool
		itemTool = newTool
	end

	if itemTool then
		InventoryService.AutoWeldTool(itemTool)

		if backpack and humanoid then
			itemTool.Parent = backpack
			humanoid:EquipTool(itemTool)
		else
			itemTool.Parent = character
		end
	end
end

function InventoryService.EquipShovel(player: Player, playerProfile: any, shovelId: string)
	local hasShovel = table.find(playerProfile.Data.OwnedShovels, shovelId) ~= nil

	if hasShovel then
		playerProfile.Data.EquippedShovel = shovelId
		InventoryService.GiveShovelToBackpack(player, shovelId)
		return true
	end

	return false
end

-- Menjual 1 item spesifik berdasarkan UUID (atau fallback ItemId)
function InventoryService.SellItem(player: Player, playerProfile: any, targetUuidOrItemId: string): (boolean, number)
	if not playerProfile or not playerProfile.Data or not playerProfile.Data.Inventory then
		return false, 0
	end

	local inventory = playerProfile.Data.Inventory
	local targetIndex: number? = nil
	local targetItem: any = nil

	for index, item in ipairs(inventory) do
		if typeof(item) == "table" then
			if item.UUID == targetUuidOrItemId or item.ItemId == targetUuidOrItemId then
				targetIndex = index
				targetItem = item
				break
			end
		end
	end

	if not targetIndex or not targetItem then
		return false, 0
	end

	local itemId = targetItem.ItemId
	local unitPrice = Items.GetSellPrice(itemId)

	-- Hapus item spesifik dari array menggunakan table.remove agar index terorganisir mulus
	table.remove(inventory, targetIndex)

	playerProfile.Data.Coins = (playerProfile.Data.Coins or 0) + unitPrice
	print(string.format("💰 Player %s sold %s (UUID: %s) for %d Coins!", player.Name, itemId, targetItem.UUID or "N/A", unitPrice))

	return true, unitPrice
end

-- Menjual seluruh isi inventaris
function InventoryService.SellAll(player: Player, playerProfile: any): (boolean, number)
	if not playerProfile or not playerProfile.Data or not playerProfile.Data.Inventory then
		return false, 0
	end

	local inventory = playerProfile.Data.Inventory
	local totalGained = 0

	for _, item in ipairs(inventory) do
		if typeof(item) == "table" and item.ItemId then
			local unitPrice = Items.GetSellPrice(item.ItemId)
			totalGained += unitPrice
		end
	end

	playerProfile.Data.Inventory = {}
	playerProfile.Data.Coins = (playerProfile.Data.Coins or 0) + totalGained

	print(string.format("💰 Player %s sold ALL items for %d Coins!", player.Name, totalGained))

	return true, totalGained
end

return InventoryService
