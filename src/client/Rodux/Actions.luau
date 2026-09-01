--!strict
local Actions = {}

function Actions.SetPlayerData(data: any)
	return {
		type = "SetPlayerData",
		data = data,
	}
end

function Actions.SetCoins(coins: number)
	return {
		type = "SetCoins",
		coins = coins,
	}
end

function Actions.SetEquippedShovel(shovelId: string)
	return {
		type = "SetEquippedShovel",
		shovelId = shovelId,
	}
end

function Actions.SetLevel(level: number)
	return {
		type = "SetLevel",
		level = level,
	}
end

return Actions
