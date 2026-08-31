--!strict
export type ShovelDef = {
	Id: string,
	Name: string,
	DigPower: number,
	SwingCooldown: number,
	Price: number,
}

local Shovels: { [string]: ShovelDef } = {
	["WoodenShovel"] = {
		Id = "WoodenShovel",
		Name = "Wooden Shovel",
		DigPower = 10,
		SwingCooldown = 0.5,
		Price = 0,
	},
	["IronShovel"] = {
		Id = "IronShovel",
		Name = "Iron Shovel",
		DigPower = 25,
		SwingCooldown = 0.4,
		Price = 500,
	},
	-- ["MythicShovel"] = {
	-- 	Id = "MythicShovel",
	-- 	Name = "Mythic Shovel",
	-- 	DigPower = 100,
	-- 	SwingCooldown = 0.25,
	-- 	Price = 5000,
	-- },
}

local ShovelsModule = {}
ShovelsModule.Dict = Shovels

function ShovelsModule.GetShovel(shovelId: string): ShovelDef?
	return Shovels[shovelId] or Shovels["WoodenShovel"]
end

return ShovelsModule
