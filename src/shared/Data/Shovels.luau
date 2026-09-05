--!strict
export type ShovelDef = {
	Id: string,
	Name: string,
	DigPower: number,
	SwingCooldown: number,
	Price: number,
	LuckBonus: number?, -- Bonus luck sekop (contoh: 0.25 = +25% Luck, 1.0 = +100% Luck)
	Icon: string?, -- Asset ID icon sekop
}

local Shovels: { [string]: ShovelDef } = {
	["WoodenShovel"] = {
		Id = "WoodenShovel",
		Name = "Wooden Shovel",
		DigPower = 45,
		SwingCooldown = 0.5,
		Price = 0,
		LuckBonus = 0,
		Icon = "rbxassetid://0",
	},
	["IronShovel"] = {
		Id = "IronShovel",
		Name = "Iron Shovel",
		DigPower = 75,
		SwingCooldown = 0.4,
		Price = 250,
		LuckBonus = 1.25, -- +25% Luck
		Icon = "rbxassetid://0",
	},
	["StandardShovel"] = {
		Id = "StandardShovel",
		Name = "Standard Shovel",
		DigPower = 75,
		SwingCooldown = 0.4,
		Price = 250,
		LuckBonus = 1.25, -- +25% Luck
		Icon = "rbxassetid://0",
	},
	-- ["MythicShovel"] = {
	-- 	Id = "MythicShovel",
	-- 	Name = "Mythic Shovel",
	-- 	DigPower = 100,
	-- 	SwingCooldown = 0.25,
	-- 	Price = 5000,
	-- 	LuckBonus = 1.0, -- +100% Luck
	-- },
}

local ShovelsModule = {}
ShovelsModule.Dict = Shovels

function ShovelsModule.GetShovel(shovelId: string): ShovelDef?
	return Shovels[shovelId] or Shovels["WoodenShovel"]
end

function ShovelsModule.GetLuckBonus(shovelId: string): number
	local shovel = Shovels[shovelId]
	if not shovel or not shovel.LuckBonus then
		return 0
	end
	return shovel.LuckBonus
end

return ShovelsModule
