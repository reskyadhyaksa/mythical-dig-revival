--!strict
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = ReplicatedStorage:FindFirstChild("Assets")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local ItemHelper = require(sharedFolder:WaitForChild("Common"):WaitForChild("ItemHelper")) :: any

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
			totalWeight += ItemHelper.GetItemWeight(item.ItemId)
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
	handle.CanTouch = false
	handle.CanQuery = false
	handle.Massless = true

	for _, descendant in tool:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = true

			if descendant ~= handle then
				local existingWeld = descendant:FindFirstChildOfClass("WeldConstraint") or descendant:FindFirstChildOfClass("Weld") or descendant:FindFirstChildOfClass("Motor6D")
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
	local character = player.Character

	-- Hapus sekop/tool lama di Backpack
	if backpack then
		for _, child in backpack:GetChildren() do
			if child:IsA("Tool") then
				child:Destroy()
			end
		end
	end

	-- Hapus tool lama yang sedang dipegang di Character
	local wasHolding = false
	if character then
		for _, child in character:GetChildren() do
			if child:IsA("Tool") then
				wasHolding = true
				child:Destroy()
			end
		end
	end

	local shovelTool: Tool? = nil
	if Assets then
		local shovelsFolder = Assets:FindFirstChild("Shovels")
		if shovelsFolder then
			local shovelTemplate = shovelsFolder:FindFirstChild(shovelId, true)
			if shovelTemplate then
				local shovelClone = shovelTemplate:Clone()
				if shovelClone:IsA("Tool") then
					InventoryService.AutoWeldTool(shovelClone)
					shovelTool = shovelClone
				end
			end
		end
	end

	-- Fallback tool jika model 3D di Assets belum ada
	if not shovelTool then
		local newTool = Instance.new("Tool")
		newTool.Name = shovelId
		newTool.RequiresHandle = false
		newTool.CanBeDropped = false
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(1, 4, 1)
		handle.Color = if shovelId == "IronShovel" then Color3.fromRGB(180, 190, 200) else Color3.fromRGB(140, 90, 50)
		handle.Material = if shovelId == "IronShovel" then Enum.Material.Metal else Enum.Material.Wood
		handle.Parent = newTool
		InventoryService.AutoWeldTool(newTool)
		shovelTool = newTool
	end

	if shovelTool and backpack then
		shovelTool.Parent = backpack
		-- Jika sebelumnya pemain sedang memegang sekop, pasang sekop baru langsung ke tangan
		if wasHolding and character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid:EquipTool(shovelTool)
			end
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

	local shovelTemplate = shovelsFolder:FindFirstChild(shovelId, true)
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

-- Equip Item dari ReplicatedStorage.Assets.Items dengan Skala Ukuran Proporsional & Motor6D
function InventoryService.EquipItemModel(character: Model, itemId: string, uuid: string?, customWeight: number?)
	local Players = game:GetService("Players")
	local player = Players:GetPlayerFromCharacter(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local backpack = player and player:FindFirstChildOfClass("Backpack")

	-- Bersihkan tool lama dan Motor6D lama dari karakter
	for _, child in character:GetChildren() do
		if child:IsA("Tool") then
			child:Destroy()
		end
	end

	for _, descendant in character:GetDescendants() do
		if descendant.Name == "ItemMotor6D" then
			descendant:Destroy()
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
	local weight = customWeight or Items.GetItemWeight(itemId)
	local rawScale = Items.GetScaleFactor(itemId, weight)

	print(string.format("✋ Equipping %s (Weight: %.2f kg | Scale: %.3fx)", itemId, weight, rawScale))

	if Assets then
		local itemsFolder = Assets:FindFirstChild("Items")
		local itemTemplate = itemsFolder and itemsFolder:FindFirstChild(itemId, true)
		if itemTemplate then
			local newTool = Instance.new("Tool")
			newTool.Name = itemId
			newTool.CanBeDropped = false
			newTool.RequiresHandle = false

			local clone = itemTemplate:Clone()

			-- Terapkan scaling bobot relatif persis sama dengan saat item dijatuhkan
			if clone:IsA("Model") then
				local baseScale = clone:GetScale()
				clone:ScaleTo(baseScale * rawScale)
			elseif clone:IsA("BasePart") then
				clone.Size = clone.Size * rawScale
			end

			-- Pastikan part utama dinamai Handle
			local handlePart: BasePart? = nil
			if clone:IsA("Model") then
				handlePart = clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart", true)
			elseif clone:IsA("BasePart") then
				handlePart = clone
			end

			if handlePart then
				handlePart.Name = "Handle"
			end

			clone.Parent = newTool
			InventoryService.AutoWeldTool(newTool)
			itemTool = newTool
		end
	end

	if not itemTool then
		-- Fallback visual jika template belum ada
		local newTool = Instance.new("Tool")
		newTool.Name = itemId
		newTool.CanBeDropped = false
		newTool.RequiresHandle = false
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(0.8, 0.8, 0.8) * math.clamp(rawScale, 0.7, 1.5)
		handle.Color = Color3.fromRGB(241, 196, 15)
		handle.Material = Enum.Material.SmoothPlastic
		handle.Parent = newTool
		InventoryService.AutoWeldTool(newTool)
		itemTool = newTool
	end

	if itemTool then
		if uuid and uuid ~= "" then
			itemTool:SetAttribute("UUID", uuid)
		end

		local handle = (itemTool:FindFirstChild("Handle", true) or itemTool:FindFirstChildWhichIsA("BasePart", true)) :: BasePart?
		local rightHand = (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")) :: BasePart?

		-- Pasang ke backpack & equip melalui humanoid
		if backpack and humanoid then
			itemTool.Parent = backpack
			humanoid:EquipTool(itemTool)
		else
			itemTool.Parent = character
		end

		-- Pasang Motor6D ke tangan kanan agar posisinya stabil, tidak bug, dan tersambung kuat
		if rightHand and handle then
			-- Hapus default RightGrip Roblox agar tidak bertabrakan dengan Motor6D
			local defaultGrip = rightHand:FindFirstChild("RightGrip")
			if defaultGrip then
				defaultGrip:Destroy()
			end

			local motor6D = Instance.new("Motor6D")
			motor6D.Name = "ItemMotor6D"
			motor6D.Part0 = rightHand
			motor6D.Part1 = handle
			-- Posisi rapi di telapak tangan
			motor6D.C0 = CFrame.new(0, -0.3, -0.2) * CFrame.Angles(math.rad(-90), 0, 0)
			motor6D.Parent = rightHand
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
			if item.UUID == targetUuidOrItemId then
				targetIndex = index
				targetItem = item
				break
			elseif item.ItemId == targetUuidOrItemId and targetIndex == nil then
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
	local unitPrice = ItemHelper.GetSellPrice(itemId)

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
			local unitPrice = ItemHelper.GetSellPrice(item.ItemId)
			totalGained += unitPrice
		end
	end

	playerProfile.Data.Inventory = {}
	playerProfile.Data.Coins = (playerProfile.Data.Coins or 0) + totalGained

	print(string.format("💰 Player %s sold ALL items for %d Coins!", player.Name, totalGained))

	return true, totalGained
end

return InventoryService
