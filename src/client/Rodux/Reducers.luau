--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rodux = require(ReplicatedStorage.Packages.Rodux)

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
		if action.data.Luck ~= nil then newState.Luck = action.data.Luck end
		if action.data.Level ~= nil then newState.Level = action.data.Level end
		if action.data.Inventory ~= nil then newState.Inventory = action.data.Inventory end
		if action.data.EquippedShovel ~= nil then newState.EquippedShovel = action.data.EquippedShovel end
		if action.data.OwnedShovels ~= nil then newState.OwnedShovels = action.data.OwnedShovels end
		
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
		return newState
	end,
})

return PlayerDataReducer
