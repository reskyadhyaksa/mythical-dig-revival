--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LevelConfig = require(ReplicatedStorage.Shared.Data.LevelConfig) :: any
local NameplateService = require(script.Parent.NameplateService) :: any

local LevelService = {}

function LevelService.AddEXP(playerProfile: any, expAmount: number, player: Player?): boolean
	if not playerProfile or not playerProfile.Data then
		return false
	end

	local data = playerProfile.Data
	data.EXP = (data.EXP or 0) + expAmount

	local leveledUp = false
	local expNeeded = LevelConfig.GetEXPForNextLevel(data.Level or 0)

	while data.EXP >= expNeeded do
		data.EXP -= expNeeded
		data.Level = (data.Level or 0) + 1
		data.Luck = LevelConfig.GetLuckString(data.Level)
		leveledUp = true
		expNeeded = LevelConfig.GetEXPForNextLevel(data.Level)
		print(string.format("🎉 PLAYER LEVELED UP! Current Level: %d (Luck: %s)", data.Level, data.Luck))

		if player then
			if player.Character then
				NameplateService.UpdateLevel(player.Character, data.Level)
			end

			local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
			local playerDataLoadedRE = remotesFolder and remotesFolder:FindFirstChild("PlayerDataLoaded") :: RemoteEvent?
			if playerDataLoadedRE then
				playerDataLoadedRE:FireClient(player, data)
			end
		end
	end

	return leveledUp
end

return LevelService
