--!strict
export type RarityType = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Secret"

local RarityEXP: { [RarityType]: number } = {
	Common = 10,
	Uncommon = 25,
	Rare = 75,
	Epic = 200,
	Legendary = 1000,
	Secret = 10000,
}

local LevelConfig = {}

-- Template Data Default untuk Player Baru (Level 0, Starter Shovel: WoodenShovel)
LevelConfig.DefaultProfileData = {
	Level = 0,
	EXP = 0,
	Coins = 0,
	OwnedShovels = { "WoodenShovel" },
	EquippedShovel = "WoodenShovel",
	Inventory = {},
}

-- Menghitung EXP yang dibutuhkan untuk naik ke level berikutnya (Progresif & Tak Terbatas)
function LevelConfig.GetEXPForNextLevel(currentLevel: number): number
	return math.floor(100 * ((currentLevel + 1) ^ 1.35))
end

-- Menghitung Kapasitas Maksimal Inventaris (Jumlah Item) berdasarkan Level Player
function LevelConfig.GetMaxInventoryCapacity(currentLevel: number): number
	if currentLevel <= 10 then
		return 100
	elseif currentLevel <= 25 then
		return 200
	elseif currentLevel <= 100 then
		return 500
	else
		return 750
	end
end

-- Menghitung Kapasitas Maksimal Berat Inventaris (kg) berdasarkan Level Player
function LevelConfig.GetMaxWeightCapacity(currentLevel: number): number
	return 50 + (currentLevel * 10)
end

-- Menghitung EXP yang didapat dari item berdasarkan Rarity
function LevelConfig.GetEXPFromRarity(rarity: RarityType): number
	return RarityEXP[rarity] or 10
end

return LevelConfig
