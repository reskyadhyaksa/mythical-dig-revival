--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local packagesFolder = ReplicatedStorage:WaitForChild("Packages")
local Rodux = require(packagesFolder:WaitForChild("Rodux"))

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local dataFolder = sharedFolder:WaitForChild("Data")
local LevelConfig = require(dataFolder:WaitForChild("LevelConfig")) :: any

local initialState = {
	Coins = 0,
	Luck = "+100%",
	Level = 0,
	Inventory = {},
	EquippedShovel = "WoodenShovel",
	OwnedShovels = { "WoodenShovel" },
}

local PlayerDataReducer = Rodux.createReducer(initialState, {
	SetPlayerData = function(state, action)
		if not action.data then return state end
		
		-- Merge data from server into state
		local newState = table.clone(state)
		
		if action.data.Coins ~= nil then newState.Coins = action.data.Coins end
		if action.data.Level ~= nil then newState.Level = action.data.Level end
		if action.data.Inventory ~= nil then newState.Inventory = action.data.Inventory end
		if action.data.EquippedShovel ~= nil then newState.EquippedShovel = action.data.EquippedShovel end
		if action.data.OwnedShovels ~= nil then newState.OwnedShovels = action.data.OwnedShovels end
		
		local currentLvl = newState.Level or 0
		newState.Luck = action.data.Luck or LevelConfig.GetLuckString(currentLvl)
		
		return newState
	end,
	
	SetCoins = function(state, action)
		local newState = table.clone(state)
		newState.Coins = action.coins
		return newState
	end,
	
	SetEquippedShovel = function(state, action)
		local newState = table.clone(state)
		newState.EquippedShovel = action.shovelId
		return newState
	end,
	
	SetLevel = function(state, action)
		local newState = table.clone(state)
		newState.Level = action.level
		newState.Luck = LevelConfig.GetLuckString(action.level or 0)
		return newState
	end,
})

return PlayerDataReducer
