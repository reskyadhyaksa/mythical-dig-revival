--!strict
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = ReplicatedStorage:WaitForChild("Assets") :: Instance
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
	local weight = customWeight or ItemHelper.GetItemWeight(itemId)

	local newItem: InventoryItem = {
		UUID = uuid,
		ItemId = itemId,
		Weight = weight,
	}

	table.insert(playerProfile.Data.Inventory, newItem)
	print(string.format("🎒 Item added! Name: %s | UUID: %s | Weight: %.1fkg", itemId, uuid, weight))

	return newItem
end

function InventoryService.AutoWeldTool(tool: any)
	if tool:IsA("Tool") then
		tool.RequiresHandle = false
		tool.CanBeDropped = false
	end

	local handle = tool:FindFirstChild("Handle") :: BasePart?
	if not handle then
		local altPart = tool:FindFirstChildWhichIsA("BasePart", true)
		if altPart then
			altPart.Name = "Handle"
			altPart.Parent = tool
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

	-- Pastikan Motor6D sudah ada di dalam Handle sesuai struktur Tool
	local existingMotor = handle:FindFirstChild("Motor6D") or handle:FindFirstChildOfClass("Motor6D")
	local motor: Motor6D
	if existingMotor and existingMotor:IsA("Motor6D") then
		motor = existingMotor
	else
		local newMotor = Instance.new("Motor6D")
		newMotor.Name = "Motor6D"
		newMotor.Parent = handle
		motor = newMotor
	end
	motor.Part1 = handle

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
					weld.Name = "Primary"
					weld.Part0 = handle
					weld.Part1 = descendant
					weld.Parent = descendant
				end
			end
		end
	end
end

-- Listener Server-side untuk memastikan Tool terhubung ke tangan karakter via Motor6D
function InventoryService.SetupCharacterToolListener(character: Model)
	local function OnChildAdded(child: Instance)
		if child:IsA("Tool") then
			child.RequiresHandle = false
			child.CanBeDropped = false

			local handle = child:FindFirstChild("Handle") :: BasePart?
			if not handle then
				handle = child:FindFirstChildWhichIsA("BasePart", true)
			end
			local arm = character:FindFirstChild("Right Arm") or character:FindFirstChild("RightHand") or character:FindFirstChild("RightUpperArm")
			if handle and arm then
				for _, desc in child:GetDescendants() do
					if desc:IsA("BasePart") then
						desc.Anchored = false
						desc.CanCollide = false
					end
				end

				local foundMotor = handle:FindFirstChild("Motor6D") or handle:FindFirstChildOfClass("Motor6D")
				local motor: Motor6D
				if foundMotor and foundMotor:IsA("Motor6D") then
					motor = foundMotor
				else
					local newMotor = Instance.new("Motor6D")
					newMotor.Name = "Motor6D"
					newMotor.Parent = handle
					motor = newMotor
				end
				motor.Part1 = handle
				motor.Part0 = arm :: BasePart

				task.defer(function()
					local rightGrip = arm:FindFirstChild("RightGrip") or handle:FindFirstChild("RightGrip")
					if rightGrip and (rightGrip:IsA("Weld") or rightGrip:IsA("ManualWeld")) then
						(rightGrip :: any).Enabled = false
					end
				end)
			end
		end
	end

	character.ChildAdded:Connect(OnChildAdded)

	for _, child in character:GetChildren() do
		if child:IsA("Tool") then
			OnChildAdded(child)
		end
	end
end

function InventoryService.GiveShovelToBackpack(player: Player, shovelId: string)
	local backpack = player:FindFirstChildOfClass("Backpack")
	local character = player.Character

	-- Hapus sekop lama di Backpack
	if backpack then
		for _, child in backpack:GetChildren() do
			if child.Name:find("Shovel") or child.Name:find("Sekop") or child.Name == shovelId then
				child:Destroy()
			end
		end
	end

	-- Hapus sekop lama yang sedang dipegang di Character
	local wasHolding = false
	if character then
		for _, child in character:GetChildren() do
			if (child:IsA("Tool") or child:IsA("Model")) and (child.Name:find("Shovel") or child.Name:find("Sekop") or child.Name == shovelId) then
				wasHolding = true
				child:Destroy()
			end
		end
	end

	local shovelClone: any = nil
	local shovelsFolder = Assets:FindFirstChild("Shovels")
	if shovelsFolder then
		local shovelTemplate = shovelsFolder:FindFirstChild(shovelId, true)
		if shovelTemplate then
			shovelClone = shovelTemplate:Clone()
		end
	end

	if shovelClone then
		if shovelClone:IsA("Tool") then
			InventoryService.AutoWeldTool(shovelClone)
		else
			-- Unanchor semua part di dalam sekop agar tidak tertinggal di koordinat (0,0,0) / ghaib
			for _, desc in shovelClone:GetDescendants() do
				if desc:IsA("BasePart") then
					desc.Anchored = false
					desc.CanCollide = false
					desc.CanTouch = false
					desc.CanQuery = false
				end
			end
		end

		if shovelClone:IsA("Tool") and backpack then
			shovelClone.Parent = backpack
			if wasHolding and character then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid:EquipTool(shovelClone)
				end
			end
		elseif character then
			shovelClone.Parent = character
		end
	end
end

function InventoryService.EquipShovelModel(character: Model, shovelId: string)
	local Players = game:GetService("Players")
	local player = Players:GetPlayerFromCharacter(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local backpack = player and player:FindFirstChildOfClass("Backpack")

	for _, child in character:GetChildren() do
		if child:IsA("Tool") or child.Name:find("Shovel") or child.Name:find("Sekop") or child.Name == shovelId then
			child:Destroy()
		end
	end

	if backpack then
		for _, child in backpack:GetChildren() do
			if child:IsA("Tool") or child.Name:find("Shovel") or child.Name:find("Sekop") or child.Name == shovelId then
				child:Destroy()
			end
		end
	end

	local shovelsFolder = Assets:FindFirstChild("Shovels")
	if shovelsFolder then
		local shovelTemplate = shovelsFolder:FindFirstChild(shovelId, true)
		if shovelTemplate then
			local shovelClone: any = shovelTemplate:Clone()
			if shovelClone:IsA("Tool") then
				InventoryService.AutoWeldTool(shovelClone)
			else
				for _, desc in shovelClone:GetDescendants() do
					if desc:IsA("BasePart") then
						desc.Anchored = false
						desc.CanCollide = false
						desc.CanTouch = false
						desc.CanQuery = false
					end
				end
			end

			if shovelClone:IsA("Tool") and backpack and humanoid then
				shovelClone.Parent = backpack
				humanoid:EquipTool(shovelClone)
			else
				shovelClone.Parent = character
			end
		end
	end
end

-- Equip Item dari ReplicatedStorage.Assets.Items dengan Skala Ukuran Proporsional & Standar Tool Grip
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
	local weight = customWeight or ItemHelper.GetItemWeight(itemId)
	local rawScale = ItemHelper.GetScaleFactor(itemId, weight)

	print(string.format("✋ Equipping %s (Weight: %.2f kg | Scale: %.3fx)", itemId, weight, rawScale))

	if Assets then
		local itemsFolder = Assets:FindFirstChild("Items")
		local itemTemplate = itemsFolder and itemsFolder:FindFirstChild(itemId, true)
		if itemTemplate then
			local newTool = Instance.new("Tool")
			newTool.Name = itemId
			newTool.CanBeDropped = false
			newTool.RequiresHandle = true

			local clone = itemTemplate:Clone()

			-- Terapkan scaling bobot relatif persis sama dengan saat item dijatuhkan
			if clone:IsA("Model") then
				local baseScale = clone:GetScale()
				clone:ScaleTo(baseScale * rawScale)

				local handlePart = clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart", true)
				if handlePart then
					handlePart.Name = "Handle"
					handlePart.Parent = newTool
					clone.Parent = newTool
				else
					local invHandle = Instance.new("Part")
					invHandle.Name = "Handle"
					invHandle.Size = Vector3.new(0.5, 0.5, 0.5)
					invHandle.Transparency = 1
					invHandle.CanCollide = false
					invHandle.Parent = newTool
					clone.Parent = newTool
				end
			elseif clone:IsA("BasePart") then
				clone.Name = "Handle"
				clone.Size = clone.Size * rawScale
				clone.Parent = newTool
			elseif clone:IsA("Tool") then
				for _, part in clone:GetChildren() do
					part.Parent = newTool
				end
				clone:Destroy()
			end

			InventoryService.AutoWeldTool(newTool)
			itemTool = newTool
		end
	end

	if not itemTool then
		-- Fallback visual jika template belum ada
		local newTool = Instance.new("Tool")
		newTool.Name = itemId
		newTool.CanBeDropped = false
		newTool.RequiresHandle = true
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

		-- Pasang ke backpack & equip melalui humanoid (Roblox akan otomatis membuat RightGrip & mengaktifkan pose memegang tool)
		if backpack and humanoid then
			itemTool.Parent = backpack
			humanoid:EquipTool(itemTool)
		else
			itemTool.Parent = character
		end
	end
end

function InventoryService.EquipShovel(player: Player, playerProfile: any, shovelId: string)
	if not playerProfile or not playerProfile.Data then
		return false
	end

	if typeof(playerProfile.Data.OwnedShovels) ~= "table" then
		playerProfile.Data.OwnedShovels = { "WoodenShovel" }
	end

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
