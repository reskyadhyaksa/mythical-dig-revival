--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local Items = require(sharedFolder:WaitForChild("Data"):WaitForChild("Items"))

export type RarityType = Items.RarityType
export type WeightRange = Items.WeightRange
export type ItemDef = Items.ItemDef

local ItemHelper = {}

-- Mengambil material tanah yang diizinkan untuk pulau tertentu
function ItemHelper.GetIslandMaterials(islandId: string): { string }
	return Items.IslandMaterials[islandId] or { "Grass", "Sand", "Slate" }
end

-- Mengambil HP galian item
function ItemHelper.GetHP(itemId: string): number
	local item = Items.Dict[itemId]
	if not item then
		return 100
	end

	if item.CustomHP then
		return item.CustomHP
	end

	return Items.RarityBaseHP[item.Rarity] or 100
end

-- Mengambil harga jual item
function ItemHelper.GetSellPrice(itemId: string): number
	local item = Items.Dict[itemId]
	if not item then
		return 10
	end

	if item.SellPrice then
		return item.SellPrice
	end

	return Items.RarityBaseSellPrice[item.Rarity] or 10
end

-- Mengambil batas kekuatan sekop minimal
function ItemHelper.GetMinDigPower(itemId: string): number
	local item = Items.Dict[itemId]
	if not item then
		return 5
	end

	if item.MinDigPower then
		return item.MinDigPower
	end

	return Items.RarityBaseMinPower[item.Rarity] or 5
end

-- Mengambil batas waktu galian (detik)
function ItemHelper.GetTimeLimit(itemId: string): number
	local item = Items.Dict[itemId]
	if not item then
		return 15
	end

	if item.TimeLimit then
		return item.TimeLimit
	end

	return Items.RarityBaseTimeLimit[item.Rarity] or 15
end

-- Mengambil rentang berat (Min & Max) untuk item tertentu
function ItemHelper.GetWeightRange(itemId: string): (number, number)
	local item = Items.Dict[itemId]
	if not item then
		return 1.0, 5.0
	end

	local defaultRange = Items.RarityDefaultWeights[item.Rarity] or { Min = 1.0, Max = 5.0 }
	local minWeight = item.MinWeight or (item.Weight and item.Weight * 0.8) or defaultRange.Min
	local maxWeight = item.MaxWeight or (item.Weight and item.Weight * 3.0) or defaultRange.Max

	return minWeight, maxWeight
end

-- Mengambil berat satuan default item
function ItemHelper.GetItemWeight(itemId: string): number
	local minW = ItemHelper.GetWeightRange(itemId)
	local item = Items.Dict[itemId]
	if item and item.Weight then
		return item.Weight
	end
	return minW
end

-- Menghasilkan variasi berat acak antara MinWeight dan MaxWeight (dengan peluang Max Ton)
-- Jika maxPowerClamp diberikan dan berat melebihi power sekop, berat diclamp ke maxPowerClamp
function ItemHelper.RollWeight(itemId: string, maxPowerClamp: number?): (number, boolean)
	local minW, maxW = ItemHelper.GetWeightRange(itemId)
	local isMaxTon = math.random(1, 20) == 1 -- Peluang 5% (1 in 20) mendapatkan Max Ton / Giant Size

	local finalWeight: number
	if isMaxTon then
		-- Mendapatkan nilai tinggi mendekati MaxWeight (85% sampai 100% dari rentang)
		local progress = math.random(85, 100) / 100
		finalWeight = minW + (maxW - minW) * progress
	else
		-- Roll normal di rentang bawah hingga menengah (5% sampai 60% dari rentang)
		local progress = math.random(5, 60) / 100
		finalWeight = minW + (maxW - minW) * progress
	end

	-- Clamp berat agar tidak melebihi kekuatan sekop saat ini jika lebih besar
	if maxPowerClamp and maxPowerClamp > 0 and finalWeight > maxPowerClamp then
		finalWeight = maxPowerClamp
	end

	finalWeight = math.floor(finalWeight * 100 + 0.5) / 100
	return finalWeight, isMaxTon
end

-- Menghitung faktor skala XYZ (3D Studs scaling) berdasarkan perbandingan berat
function ItemHelper.GetScaleFactor(itemId: string, actualWeight: number): number
	local minW, maxW = ItemHelper.GetWeightRange(itemId)
	if maxW <= minW then
		return 1.0
	end

	-- Hitung progres persentase berat (0.0 sampai 1.0)
	local progress = math.clamp((actualWeight - minW) / (maxW - minW), 0, 1)

	-- Bobot Terkecil / Normal = 1.0x, Bobot MaxTon = 1.50x
	return 1.0 + (progress * 0.50)
end

-- Mengecek apakah item berstatus Max Ton (mencapai 80% ke atas dari rentang MaxWeight)
function ItemHelper.IsMaxTon(itemId: string, actualWeight: number): boolean
	local minW, maxW = ItemHelper.GetWeightRange(itemId)
	if maxW <= minW then
		return false
	end
	local progress = (actualWeight - minW) / (maxW - minW)
	return progress >= 0.80
end

-- Menghitung total berat seluruh isi inventaris (kg)
function ItemHelper.GetTotalInventoryWeight(inventory: any): number
	if not inventory or typeof(inventory) ~= "table" then
		return 0
	end

	local totalWeight = 0

	if #inventory > 0 then
		-- Array inventaris berbasis UUID unik
		for _, item in ipairs(inventory) do
			if typeof(item) == "table" then
				if item.Weight then
					totalWeight += item.Weight
				elseif item.ItemId then
					totalWeight += ItemHelper.GetItemWeight(item.ItemId)
				end
			elseif typeof(item) == "string" then
				totalWeight += ItemHelper.GetItemWeight(item)
			end
		end
	else
		-- Fallback key-value dictionary (legacy support)
		for itemId, count in pairs(inventory) do
			if typeof(count) == "number" and count > 0 then
				local unitWeight = ItemHelper.GetItemWeight(itemId)
				totalWeight += (unitWeight * count)
			end
		end
	end

	return totalWeight
end

-- Menghasilkan item acak berdasarkan lokasi pulau, tier, material, dan power sekop
function ItemHelper.GetRandomItem(
	islandId: string?,
	forcedTier: RarityType?,
	groundMaterial: string?,
	shovelPower: number?,
	luckMultiplier: number?
): ItemDef
	local candidateList: { ItemDef } = {}

	for _, itemDef in Items.Dict do
		if islandId and itemDef.IslandId and itemDef.IslandId ~= islandId then
			continue
		end

		if forcedTier and itemDef.Rarity ~= forcedTier then
			continue
		end

		-- Filter Kekuatan Sekop: Item tidak akan masuk roll jika kekuatan sekop belum mencukupi MinDigPower
		if shovelPower then
			local minPower = ItemHelper.GetMinDigPower(itemDef.Id)
			if shovelPower < minPower then
				continue
			end
		end

		if groundMaterial then
			local reqMat = itemDef.RequiredMaterial or (itemDef.IslandId and Items.IslandMaterials[itemDef.IslandId])
			if reqMat then
				if type(reqMat) == "string" then
					if reqMat ~= groundMaterial then
						continue
					end
				elseif type(reqMat) == "table" then
					if not table.find(reqMat :: { string }, groundMaterial) then
						continue
					end
				end
			end
		end

		table.insert(candidateList, itemDef)
	end

	-- Urutkan item dari yang paling langka (Chance terbesar) ke paling umum (Chance terkecil)
	table.sort(candidateList, function(a, b)
		return a.Chance > b.Chance
	end)

	-- Jika dipaksa mendapatkan tier tertentu (Admin/Dev Cheat / Potion Effect)
	if forcedTier then
		if #candidateList > 0 then
			return candidateList[math.random(1, #candidateList)]
		end
	end

	-- 1. Evaluasi roll dari item terlangka (Chance > 2) dengan dukungan Luck Boost Multiplier
	local multiplier = math.max(1.0, luckMultiplier or 1.0)
	local baseCandidates: { ItemDef } = {}

	for _, itemDef in ipairs(candidateList) do
		if itemDef.Chance > 2 then
			local effectiveChance = math.max(1, math.floor(itemDef.Chance / multiplier))
			if math.random(1, effectiveChance) == 1 then
				return itemDef
			end
		else
			table.insert(baseCandidates, itemDef)
		end
	end

	-- 2. Jika tidak ada item langka yang kena roll, pilih secara adil dan merata di antara base/common items (misal Ancient Nail vs Rabbit Skeleton)
	if #baseCandidates > 0 then
		return baseCandidates[math.random(1, #baseCandidates)]
	end

	-- Fallback jika candidateList tidak kosong
	return candidateList[#candidateList] or Items.Dict["AncientNail"]
end

return ItemHelper
