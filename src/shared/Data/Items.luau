--!strict
export type RarityType = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Secret"

export type ItemDef = {
	Id: string,
	Name: string,
	Rarity: RarityType,
	Chance: number,
	CustomHP: number?,
	IslandId: string?,
	RequiredMaterial: (string | { string })?,
	SellPrice: number?, -- Harga jual item ke Toko / Sell UI (opsional)
	MinDigPower: number?, -- Kekuatan sekop minimal yang dibutuhkan
	TimeLimit: number?, -- Batas waktu minigame (detik) sebelum item lepas/rusak
}

local RarityBaseHP: { [RarityType]: number } = {
	Common = 50,
	Uncommon = 150,
	Rare = 400,
	Epic = 1000,
	Legendary = 2500,
	Secret = 10000,
}

local RarityBaseSellPrice: { [RarityType]: number } = {
	Common = 10,
	Uncommon = 25,
	Rare = 100,
	Epic = 500,
	Legendary = 2500,
	Secret = 100000,
}

local RarityBaseMinPower: { [RarityType]: number } = {
	Common = 5,
	Uncommon = 15,
	Rare = 35,
	Epic = 60,
	Legendary = 90,
	Secret = 150,
}

local RarityBaseTimeLimit: { [RarityType]: number } = {
	Common = 20,
	Uncommon = 15,
	Rare = 12,
	Epic = 10,
	Legendary = 8,
	Secret = 6,
}

local ItemsByIsland: { [string]: { [string]: ItemDef } } = {
	["Island1"] = {
		["IronOre"] = {
			Id = "IronOre",
			Name = "Iron Ore",
			Rarity = "Common",
			Chance = 2,
			RequiredMaterial = { "Grass", "Sand" },
		},
		["CopperOre"] = {
			Id = "CopperOre",
			Name = "Copper Ore",
			Rarity = "Common",
			Chance = 2,
			RequiredMaterial = "Sand",
		},
		["ObsidianOre"] = {
			Id = "ObsidianOre",
			Name = "Obsidian Ore",
			Rarity = "Rare",
			Chance = 100,
			RequiredMaterial = "Slate",
		},
		["MithrilOre"] = {
			Id = "MithrilOre",
			Name = "Mithril Ore",
			Rarity = "Legendary",
			Chance = 2500,
		},
	},

	["Island2"] = {
		["WyvernCore"] = {
			Id = "WyvernCore",
			Name = "Wyvern Core",
			Rarity = "Secret",
			Chance = 1_000_000,
			CustomHP = 50000,
		},
		["WyvernRightArmBone"] = {
			Id = "WyvernRightArmBone",
			Name = "Wyvern Right Arm Bone",
			Rarity = "Secret",
			Chance = 3_000_000,
			CustomHP = 75000,
		},
		["WyvernLeftArmBone"] = {
			Id = "WyvernLeftArmBone",
			Name = "Wyvern Left Arm Bone",
			Rarity = "Secret",
			Chance = 4_000_000,
			CustomHP = 100000,
		},
	},
}

-- Flatten Items dictionary secara otomatis untuk pencarian cepat & penetapan IslandId
local Items: { [string]: ItemDef } = {}
for islandId, itemList in ItemsByIsland do
	for itemId, itemDef in itemList do
		itemDef.IslandId = islandId
		Items[itemId] = itemDef
	end
end

local ItemsModule = {}
ItemsModule.Dict = Items
ItemsModule.ByIsland = ItemsByIsland

function ItemsModule.GetHP(itemId: string): number
	local item = Items[itemId]
	if not item then
		return 100
	end

	if item.CustomHP then
		return item.CustomHP
	end

	return RarityBaseHP[item.Rarity] or 100
end

function ItemsModule.GetSellPrice(itemId: string): number
	local item = Items[itemId]
	if not item then
		return 10
	end

	if item.SellPrice then
		return item.SellPrice
	end

	return RarityBaseSellPrice[item.Rarity] or 10
end

function ItemsModule.GetMinDigPower(itemId: string): number
	local item = Items[itemId]
	if not item then
		return 5
	end

	if item.MinDigPower then
		return item.MinDigPower
	end

	return RarityBaseMinPower[item.Rarity] or 5
end

function ItemsModule.GetTimeLimit(itemId: string): number
	local item = Items[itemId]
	if not item then
		return 15
	end

	if item.TimeLimit then
		return item.TimeLimit
	end

	return RarityBaseTimeLimit[item.Rarity] or 15
end

function ItemsModule.GetRandomItem(islandId: string?, forcedTier: RarityType?, groundMaterial: string?): ItemDef
	local candidateList: { ItemDef } = {}

	for _, itemDef in Items do
		if islandId and itemDef.IslandId and itemDef.IslandId ~= islandId then
			continue
		end

		if forcedTier and itemDef.Rarity ~= forcedTier then
			continue
		end

		if groundMaterial and itemDef.RequiredMaterial then
			local reqMat = itemDef.RequiredMaterial
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

	-- Evaluasi roll dari item terlangka (1/4M -> 1/3M -> 1/1M -> 1/2500 -> 1/2)
	for _, itemDef in candidateList do
		if itemDef.Chance <= 1 then
			return itemDef
		end

		if math.random(1, itemDef.Chance) == 1 then
			return itemDef
		end
	end

	-- Jika semua roll misal di atas gagal, kembalikan item termudah
	return candidateList[#candidateList] or Items["IronOre"]
end

return ItemsModule
