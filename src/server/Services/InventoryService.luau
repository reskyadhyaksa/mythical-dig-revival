--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = ReplicatedStorage:FindFirstChild("Assets")
local Items = require(ReplicatedStorage.Shared.Data.Items) :: any

local InventoryService = {}

function InventoryService.GetTotalItemCount(inventory: { [string]: number }?): number
	if not inventory then
		return 0
	end

	local total = 0
	for _, count in pairs(inventory) do
		total += count
	end

	return total
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

function InventoryService.EquipShovelModel(character: Model, shovelId: string)
	local Players = game:GetService("Players")
	local player = Players:GetPlayerFromCharacter(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local backpack = player and player:FindFirstChildOfClass("Backpack")

	-- Hapus sekop lama dari karakter & backpack
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

function InventoryService.EquipShovel(player: Player, playerProfile: any, shovelId: string)
	local hasShovel = table.find(playerProfile.Data.OwnedShovels, shovelId) ~= nil

	if hasShovel then
		playerProfile.Data.EquippedShovel = shovelId

		if player.Character then
			InventoryService.EquipShovelModel(player.Character, shovelId)
		end

		return true
	end

	return false
end

function InventoryService.SellItem(player: Player, playerProfile: any, itemId: string, amount: number?): (boolean, number)
	if not playerProfile or not playerProfile.Data or not playerProfile.Data.Inventory then
		return false, 0
	end

	local inventory = playerProfile.Data.Inventory
	local currentCount = inventory[itemId] or 0

	if currentCount <= 0 then
		return false, 0
	end

	local sellAmount = amount or currentCount
	if sellAmount > currentCount then
		sellAmount = currentCount
	end

	local unitPrice = Items.GetSellPrice(itemId)
	local totalCoinsGained = unitPrice * sellAmount

	inventory[itemId] = currentCount - sellAmount
	if inventory[itemId] <= 0 then
		inventory[itemId] = nil
	end

	playerProfile.Data.Coins = (playerProfile.Data.Coins or 0) + totalCoinsGained
	print(string.format("💰 Player sold %d x %s for %d Coins!", sellAmount, itemId, totalCoinsGained))

	return true, totalCoinsGained
end

function InventoryService.SellAll(player: Player, playerProfile: any): (boolean, number)
	if not playerProfile or not playerProfile.Data or not playerProfile.Data.Inventory then
		return false, 0
	end

	local inventory = playerProfile.Data.Inventory
	local totalGained = 0

	for itemId, count in pairs(inventory) do
		if count > 0 then
			local unitPrice = Items.GetSellPrice(itemId)
			totalGained += (unitPrice * count)
		end
	end

	playerProfile.Data.Inventory = {}
	playerProfile.Data.Coins = (playerProfile.Data.Coins or 0) + totalGained

	print(string.format("💰 Player sold ALL items for %d Coins!", totalGained))

	return true, totalGained
end

return InventoryService
