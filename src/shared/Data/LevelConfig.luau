--!strict
export type RarityType = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Secret"

local RarityEXP: { [RarityType]: number } = {
	Common = 100,
	Uncommon = 250,
	Rare = 750,
	Epic = 2000,
	Legendary = 10000,
	Secret = 100000,
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

-- Menghitung Kapasitas Maksimal Inventaris (Jumlah Slot Item) berdasarkan Level Player
function LevelConfig.GetMaxInventoryCapacity(currentLevel: number): number
	return 50 + (currentLevel * 10) -- Level 0 = 50 item, Level 5 = 100 item, Level 10 = 150 item
end

-- Helper kapasitas berat (opsional fallback)
function LevelConfig.GetMaxWeightCapacity(currentLevel: number): number
	return 50 + (currentLevel * 10)
end

-- Menghitung total Luck stat berdasarkan Level Player (+100% base, +10% per level)
function LevelConfig.GetTotalLuck(currentLevel: number): number
	return 100 + (math.max(0, currentLevel) * 10) -- Level 0 = 100%, Level 1 = 110%, Level 10 = 200%
end

function LevelConfig.GetLuckString(currentLevel: number): string
	return string.format("+%d%%", LevelConfig.GetTotalLuck(currentLevel))
end

-- Menghitung EXP yang didapat dari item berdasarkan Rarity
function LevelConfig.GetEXPFromRarity(rarity: RarityType): number
	return RarityEXP[rarity] or 10
end

return LevelConfig
