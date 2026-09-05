--!strict
export type RarityType = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Secret"

export type WeightRange = {
	Min: number,
	Max: number,
}

export type ItemDef = {
	Id: string,
	Name: string,
	Rarity: RarityType,
	Chance: number,
	Icon: string?, -- Asset ID icon item (contoh: "rbxassetid://0")
	CustomHP: number?,
	IslandId: string?,
	RequiredMaterial: (string | { string })?,
	SellPrice: number?, -- Harga jual item ke Toko / Sell UI (opsional)
	MinDigPower: number?, -- Kekuatan sekop minimal yang dibutuhkan
	TimeLimit: number?, -- Batas waktu minigame (detik) sebelum item lepas/rusak
	MinWeight: number?, -- Berat minimum (kg) item ini saat di-roll
	MaxWeight: number?, -- Berat maksimum / Max Ton (kg) item ini saat di-roll
	Weight: number?, -- Berat default (opsional fallback jika MinWeight & MaxWeight tidak diset)
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
	Uncommon = 10,
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

-- Default rentang berat (Min & Max Weight dalam kg) berdasarkan Rarity jika tidak diset per item
local RarityDefaultWeights: { [RarityType]: WeightRange } = {
	Common = { Min = 1.0, Max = 5.0 },
	Uncommon = { Min = 3.0, Max = 15.0 },
	Rare = { Min = 8.0, Max = 40.0 },
	Epic = { Min = 20.0, Max = 100.0 },
	Legendary = { Min = 40.0, Max = 250.0 },
	Secret = { Min = 100.0, Max = 1000.0 },
}

-- Material tanah yang diizinkan untuk menggali per pulau
local IslandMaterials: { [string]: { string } } = {
	["Island1"] = { "Grass", "Sand" },
	["Island2"] = { "Slate", "Basalt", "Rock" },
}

local ItemsByIsland: { [string]: { [string]: ItemDef } } = {
	["Island1"] = {
		["AncientNail"] = {
			Id = "AncientNail",
			Name = "Ancient Nail",
			Rarity = "Common",
			Chance = 2,
			Icon = "rbxassetid://0",
		},
		["RabbitSkeleton"] = {
			Id = "RabbitSkeleton",
			Name = "Rabbit Skeleton",
			Rarity = "Uncommon",
			Chance = 2,
			MaxWeight = 10,
			Icon = "rbxassetid://0",
		},
		["RavenSkeleton"] = {
			Id = "RavenSkeleton",
			Name = "Raven Skeleton",
			Rarity = "Uncommon",
			Chance = 1000,
			Icon = "rbxassetid://0",
			-- RequiredMaterial = "Slate",
		},
		["StoneGolem"] = {
			Id = "StoneGolem",
			Name = "Stone Golem",
			Rarity = "Uncommon",
			Chance = 2500,
			Icon = "rbxassetid://0",
		},
	},

	["Island2"] = {
		["WyvernCore"] = {
			Id = "WyvernCore",
			Name = "Wyvern Core",
			Rarity = "Secret",
			Chance = 1_000_000,
			CustomHP = 50000,
			Icon = "rbxassetid://0",
		},
		["WyvernRightArmBone"] = {
			Id = "WyvernRightArmBone",
			Name = "Wyvern Right Arm Bone",
			Rarity = "Secret",
			Chance = 3_000_000,
			CustomHP = 75000,
			Icon = "rbxassetid://0",
		},
		["WyvernLeftArmBone"] = {
			Id = "WyvernLeftArmBone",
			Name = "Wyvern Left Arm Bone",
			Rarity = "Secret",
			Chance = 4_000_000,
			CustomHP = 100000,
			Icon = "rbxassetid://0",
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

return {
	Dict = Items,
	ByIsland = ItemsByIsland,
	IslandMaterials = IslandMaterials,
	RarityBaseHP = RarityBaseHP,
	RarityBaseSellPrice = RarityBaseSellPrice,
	RarityBaseMinPower = RarityBaseMinPower,
	RarityBaseTimeLimit = RarityBaseTimeLimit,
	RarityDefaultWeights = RarityDefaultWeights,
}
