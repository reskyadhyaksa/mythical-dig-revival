--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LevelConfig = require(ReplicatedStorage.Shared.Data.LevelConfig) :: any
local Shovels = require(ReplicatedStorage.Shared.Data.Shovels) :: any
local DataService = require(script.Services.DataService) :: any
local NameplateService = require(script.Services.NameplateService) :: any
local InventoryService = require(script.Services.InventoryService) :: any
local DigService = require(script.Services.DigService) :: any

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
local equipItemRE = GetOrCreateRemoteEvent("EquipItem")
local playerDataLoadedRE = GetOrCreateRemoteEvent("PlayerDataLoaded")

cancelDigRE.OnServerEvent:Connect(function(player: Player)
	DigService.CancelDig(player)
end)

equipItemRE.OnServerEvent:Connect(function(player: Player, itemId: string, uuid: string?)
	local profile = DataService.GetProfile(player)
	if profile and profile.Data and profile.Data.Inventory then
		local hasItem = false
		local itemWeight: number? = nil
		for _, item in ipairs(profile.Data.Inventory) do
			if typeof(item) == "table" then
				if uuid and uuid ~= "" then
					if item.UUID == uuid then
						hasItem = true
						itemWeight = item.Weight
						break
					end
				else
					if item.ItemId == itemId then
						hasItem = true
						itemWeight = item.Weight
						break
					end
				end
			elseif item == itemId then
				hasItem = true
				break
			end
		end

		if hasItem and player.Character then
			InventoryService.EquipItemModel(player.Character, itemId, uuid, itemWeight)
		end
	end
end)

-- Data request dari Client UI (Memuat Coins & Level tersimpan)
getPlayerDataRF.OnServerInvoke = function(player: Player)
	local profile = DataService.GetProfile(player)
	local attempts = 0
	-- Tunggu hingga profile selesai dimuat dari DataStore jika client me-request di frame 1
	while (not profile or not profile.Data) and attempts < 35 and player:IsDescendantOf(Players) do
		task.wait(0.1)
		attempts += 1
		profile = DataService.GetProfile(player)
	end

	if profile and profile.Data then
		local lvl = profile.Data.Level or 0
		profile.Data.Luck = LevelConfig.GetLuckString(lvl)
		return profile.Data
	end
	return nil
end

-- Mulai galian dengan dukungan Luck Boost Multiplier
startDigRF.OnServerInvoke = function(player: Player, luckMultiplier: number?)
	local profile = DataService.GetProfile(player)
	if not profile then return nil end

	local activeDig = DigService.StartDigNode(player, profile, luckMultiplier)
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
	local profile = DataService.GetProfile(player)
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
	local profile = DataService.GetProfile(player)
	if profile then
		InventoryService.SellItem(player, profile, itemId, amount)
	end
end)

sellAllRE.OnServerEvent:Connect(function(player: Player)
	local profile = DataService.GetProfile(player)
	if profile then
		InventoryService.SellAll(player, profile)
	end
end)

-- Beli Sekop
buyShovelRE.OnServerEvent:Connect(function(player: Player, shovelId: string)
	local profile = DataService.GetProfile(player)
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
		playerDataLoadedRE:FireClient(player, profile.Data)
		print(string.format("🛒 Player %s bought %s for %d Coins!", player.Name, shovelDef.Name, price))
	end
end)

-- Pasang Sekop
equipShovelRE.OnServerEvent:Connect(function(player: Player, shovelId: string)
	local profile = DataService.GetProfile(player)
	if profile and profile.Data then
		local success = InventoryService.EquipShovel(player, profile, shovelId)
		if success then
			playerDataLoadedRE:FireClient(player, profile.Data)
			print(string.format("⚒️ Player %s equipped %s!", player.Name, shovelId))
		end
	end
end)

local function OnPlayerAdded(player: Player)
	-- Inisialisasi DataStore Persistent via ProfileService
	local profile = DataService.OnPlayerAdded(player)
	if profile and profile.Data then
		playerDataLoadedRE:FireClient(player, profile.Data)
	end

	-- Taruh sekop di Backpack & buat Overhead Nameplate saat karakter player muncul/respawn (tanpa auto-equip ke tangan)
	player.CharacterAdded:Connect(function(character: Model)
		task.wait(0.2)
		local currentProfile = DataService.GetProfile(player)
		if currentProfile and currentProfile.Data then
			local equippedShovel = currentProfile.Data.EquippedShovel or "WoodenShovel"
			local level = currentProfile.Data.Level or 0
			InventoryService.GiveShovelToBackpack(player, equippedShovel)
			NameplateService.CreateNameplate(player, character, level)
		end
	end)

	if player.Character then
		local equippedShovel = profile and profile.Data and profile.Data.EquippedShovel or "WoodenShovel"
		local level = profile and profile.Data and profile.Data.Level or 0
		InventoryService.GiveShovelToBackpack(player, equippedShovel)
		NameplateService.CreateNameplate(player, player.Character, level)
	end
end

local function OnPlayerRemoving(player: Player)
	DataService.OnPlayerRemoving(player)
end

Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)

for _, player in Players:GetPlayers() do
	task.spawn(OnPlayerAdded, player)
end

print("🚀 Server DataStore initialized! Persistent Coins, Level & Inventory active.")
