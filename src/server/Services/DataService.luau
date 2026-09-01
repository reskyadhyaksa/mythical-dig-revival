--!strict
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerPackages = ServerScriptService:WaitForChild("ServerPackages", 5)
local ProfileService: any = nil

if ServerPackages and ServerPackages:FindFirstChild("ProfileService") then
	local success, result = pcall(function()
		return require(ServerPackages.ProfileService)
	end)
	if success then
		ProfileService = result
	end
end

local LevelConfig = require(ReplicatedStorage.Shared.Data.LevelConfig) :: any

local ProfileTemplate = {
	Coins = 0,
	Level = 0,
	EXP = 0,
	OwnedShovels = { "WoodenShovel" },
	EquippedShovel = "WoodenShovel",
	Inventory = {},
}

local ProfileStore = if ProfileService then ProfileService.GetProfileStore("PlayerData_v2", ProfileTemplate) else nil
local Profiles: { [Player]: any } = {}

local DataService = {}

-- Load / Inisialisasi DataStore Player saat bergabung
function DataService.OnPlayerAdded(player: Player): any
	if ProfileStore then
		local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
		if profile ~= nil then
			profile:AddUserId(player.UserId)
			profile:Reconcile()
			profile:ListenToRelease(function()
				Profiles[player] = nil
				player:Kick("Data session loaded on another device.")
			end)

			if player:IsDescendantOf(Players) == true then
				Profiles[player] = profile
				print(string.format("✅ DataStore Loaded for %s! [Coins: %d | Level: %d | EXP: %d]", player.Name, profile.Data.Coins or 0, profile.Data.Level or 0, profile.Data.EXP or 0))
				return profile
			else
				profile:Release()
			end
		else
			player:Kick("Gagal memuat DataStore player. Silakan bergabung kembali.")
		end
	else
		-- Fallback In-Memory Profile jika ProfileService / DataStore tidak aktif
		print("⚠️ ProfileService tidak terdeteksi. Menggunakan in-memory data temporary.")
		local fallbackProfile = {
			Data = {
				Coins = LevelConfig.DefaultProfileData and LevelConfig.DefaultProfileData.Coins or 0,
				Level = LevelConfig.DefaultProfileData and LevelConfig.DefaultProfileData.Level or 0,
				EXP = LevelConfig.DefaultProfileData and LevelConfig.DefaultProfileData.EXP or 0,
				OwnedShovels = { "WoodenShovel" },
				EquippedShovel = "WoodenShovel",
				Inventory = {},
			},
		}
		Profiles[player] = fallbackProfile
		return fallbackProfile
	end
	return nil
end

-- Simpan & Release DataStore saat player keluar
function DataService.OnPlayerRemoving(player: Player)
	local profile = Profiles[player]
	if profile ~= nil then
		if profile.Release then
			profile:Release()
		end
		Profiles[player] = nil
		print(string.format("💾 Data saved and released for %s", player.Name))
	end
end

-- Mendapatkan Profile Data player aktif
function DataService.GetProfile(player: Player): any
	return Profiles[player]
end

-- Function penolong untuk menambah / mengurangi Coins
function DataService.AddCoins(player: Player, amount: number): number
	local profile = Profiles[player]
	if profile and profile.Data then
		local current = profile.Data.Coins or 0
		profile.Data.Coins = math.max(0, current + amount)
		return profile.Data.Coins
	end
	return 0
end

-- Function penolong untuk mengecek Level
function DataService.GetLevel(player: Player): number
	local profile = Profiles[player]
	if profile and profile.Data then
		return profile.Data.Level or 0
	end
	return 0
end

-- Function penolong untuk mengecek Coins
function DataService.GetCoins(player: Player): number
	local profile = Profiles[player]
	if profile and profile.Data then
		return profile.Data.Coins or 0
	end
	return 0
end

return DataService
