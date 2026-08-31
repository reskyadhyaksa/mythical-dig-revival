--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LevelConfig = require(ReplicatedStorage.Shared.Data.LevelConfig) :: any
local Shovels = require(ReplicatedStorage.Shared.Data.Shovels) :: any
local InventoryService = require(script.Services.InventoryService) :: any
local DigService = require(script.Services.DigService) :: any

local playerProfiles: { [Player]: any } = {}

-- Setup RemoteEvents & RemoteFunctions di ReplicatedStorage
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
end

local function GetOrCreateRemoteEvent(name: string): RemoteEvent
	local remote = remotesFolder:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remotesFolder
	end
	return remote :: RemoteEvent
end

local function GetOrCreateRemoteFunction(name: string): RemoteFunction
	local remote = remotesFolder:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = remotesFolder
	end
	return remote :: RemoteFunction
end

local getPlayerDataRF = GetOrCreateRemoteFunction("GetPlayerData")
local startDigRF = GetOrCreateRemoteFunction("StartDig")
local swingShovelRF = GetOrCreateRemoteFunction("SwingShovel")
local cancelDigRE = GetOrCreateRemoteEvent("CancelDig")
local sellItemRE = GetOrCreateRemoteEvent("SellItem")
local sellAllRE = GetOrCreateRemoteEvent("SellAll")
local buyShovelRE = GetOrCreateRemoteEvent("BuyShovel")
local equipShovelRE = GetOrCreateRemoteEvent("EquipShovel")

cancelDigRE.OnServerEvent:Connect(function(player: Player)
	DigService.CancelDig(player)
end)

-- Data request dari Client UI
getPlayerDataRF.OnServerInvoke = function(player: Player)
	local profile = playerProfiles[player]
	if profile then
		return profile.Data
	end
	return nil
end

-- Mulai galian
startDigRF.OnServerInvoke = function(player: Player)
	local profile = playerProfiles[player]
	if not profile then return nil end

	local activeDig = DigService.StartDigNode(player, profile)
	if activeDig and activeDig.TargetItem then
		return {
			Rarity = activeDig.TargetItem.Rarity,
			CurrentHp = activeDig.CurrentHP,
			MaxHp = activeDig.MaxHP,
			ItemName = activeDig.TargetItem.Name,
			TimeLimit = activeDig.TimeLimit,
			MinDigPower = activeDig.MinDigPower,
			ShovelPower = activeDig.ShovelPower,
			IsTooWeak = activeDig.IsTooWeak,
		}
	end

	return nil
end

-- Swing Sekop (Return state HP galian terbaru ke Client)
swingShovelRF.OnServerInvoke = function(player: Player)
	local profile = playerProfiles[player]
	if not profile then return nil end

	DigService.SwingShovel(player, profile)

	local activeDig = DigService.GetActiveDig(player)
	if activeDig then
		return {
			CurrentHp = activeDig.CurrentHP,
			MaxHp = activeDig.MaxHP,
			IsFinished = false,
		}
	else
		return {
			CurrentHp = 0,
			MaxHp = 100,
			IsFinished = true,
		}
	end
end

-- Jual Item
sellItemRE.OnServerEvent:Connect(function(player: Player, itemId: string, amount: number)
	local profile = playerProfiles[player]
	if profile then
		InventoryService.SellItem(player, profile, itemId, amount)
	end
end)

sellAllRE.OnServerEvent:Connect(function(player: Player)
	local profile = playerProfiles[player]
	if profile then
		InventoryService.SellAll(player, profile)
	end
end)

-- Beli Sekop
buyShovelRE.OnServerEvent:Connect(function(player: Player, shovelId: string)
	local profile = playerProfiles[player]
	if not profile or not profile.Data then return end

	local shovelDef = Shovels.GetShovel(shovelId)
	if not shovelDef then return end

	local isOwned = table.find(profile.Data.OwnedShovels, shovelId) ~= nil
	if isOwned then return end

	local price = shovelDef.Price or 0
	local currentCoins = profile.Data.Coins or 0

	if currentCoins >= price then
		profile.Data.Coins = currentCoins - price
		table.insert(profile.Data.OwnedShovels, shovelId)
		InventoryService.EquipShovel(player, profile, shovelId)
		print(string.format("🛒 Player bought %s for %d Coins!", shovelDef.Name, price))
	end
end)

-- Pasang Sekop
equipShovelRE.OnServerEvent:Connect(function(player: Player, shovelId: string)
	local profile = playerProfiles[player]
	if profile then
		InventoryService.EquipShovel(player, profile, shovelId)
	end
end)

local function OnPlayerAdded(player: Player)
	-- Inisialisasi Data Default Player (WoodenShovel sebagai sekop bawaan level 0)
	playerProfiles[player] = {
		Data = {
			Level = LevelConfig.DefaultProfileData.Level,
			EXP = LevelConfig.DefaultProfileData.EXP,
			Coins = LevelConfig.DefaultProfileData.Coins,
			OwnedShovels = { "WoodenShovel" },
			EquippedShovel = "WoodenShovel",
			Inventory = {},
		},
	}

	-- Pasang fisik sekop WoodenShovel saat karakter player muncul/respawn
	player.CharacterAdded:Connect(function(character: Model)
		task.wait(0.2)
		local profile = playerProfiles[player]
		if profile and profile.Data then
			local equippedShovel = profile.Data.EquippedShovel or "WoodenShovel"
			InventoryService.EquipShovelModel(character, equippedShovel)
		end
	end)

	if player.Character then
		InventoryService.EquipShovelModel(player.Character, "WoodenShovel")
	end
end

local function OnPlayerRemoving(player: Player)
	playerProfiles[player] = nil
end

Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)

for _, player in Players:GetPlayers() do
	task.spawn(OnPlayerAdded, player)
end

print("🚀 Server initialized! Remotes and auto-equip active.")
