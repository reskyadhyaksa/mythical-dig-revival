--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Items = require(ReplicatedStorage.Shared.Data.Items) :: any
local Shovels = require(ReplicatedStorage.Shared.Data.Shovels) :: any
local LevelConfig = require(ReplicatedStorage.Shared.Data.LevelConfig) :: any
local ZoneService = require(script.Parent.ZoneService) :: any
local LevelService = require(script.Parent.LevelService) :: any
local InventoryService = require(script.Parent.InventoryService) :: any

type ActiveDigState = {
	TargetItem: any,
	CurrentHP: number,
	MaxHP: number,
	LastSwingTime: number,
	StartTime: number,
	TimeLimit: number,
	MinDigPower: number,
	ShovelPower: number,
	IsTooWeak: boolean,
}

local DigService = {}
local activeDigs: { [Player]: ActiveDigState } = {}
local forcedNextTier: { [Player]: string } = {}

function DigService.SetNextTier(player: Player, rarity: string)
	forcedNextTier[player] = rarity
end

function DigService.GetActiveDig(player: Player): ActiveDigState?
	return activeDigs[player]
end

function DigService.CancelDig(player: Player)
	activeDigs[player] = nil
end

function DigService.StartDigNode(player: Player, playerProfile: any): ActiveDigState?
	if activeDigs[player] then
		return activeDigs[player]
	end

	-- Cek Batas Maksimal Kapasitas Inventaris Player Berdasarkan Level
	local playerLevel = playerProfile.Data and playerProfile.Data.Level or 0
	local maxCapacity = LevelConfig.GetMaxInventoryCapacity(playerLevel)
	local currentCount = InventoryService.GetTotalItemCount(playerProfile.Data and playerProfile.Data.Inventory)

	if currentCount >= maxCapacity then
		print("⚠️ INVENTORY FULL! Clean up inventory before digging.")
		return nil
	end

	local islandId = ZoneService.GetPlayerIsland(player)
	local groundMaterial = ZoneService.GetPlayerGroundMaterial(player)

	-- Bug Fix: Galian HANYA diperbolehkan di tanah Grass, Sand, Slate!
	if not groundMaterial then
		print("⚠️ CANNOT DIG! Player is standing on non-allowed ground material.")
		return nil
	end

	local equippedShovelId = playerProfile.Data and playerProfile.Data.EquippedShovel or "WoodenShovel"
	local shovelInfo = Shovels.GetShovel(equippedShovelId)
	local shovelPower = shovelInfo and shovelInfo.DigPower or 10

	local forcedTier = forcedNextTier[player]
	forcedNextTier[player] = nil -- Reset setelah digunakan 1x

	local selectedItem = Items.GetRandomItem(islandId, forcedTier, groundMaterial)
	local itemHP = Items.GetHP(selectedItem.Id)
	local minDigPower = Items.GetMinDigPower(selectedItem.Id)
	local timeLimit = Items.GetTimeLimit(selectedItem.Id)

	local isTooWeak = shovelPower < minDigPower

	local state = {
		TargetItem = selectedItem,
		CurrentHP = itemHP,
		MaxHP = itemHP,
		LastSwingTime = 0,
		StartTime = os.clock(),
		TimeLimit = timeLimit,
		MinDigPower = minDigPower,
		ShovelPower = shovelPower,
		IsTooWeak = isTooWeak,
	}

	activeDigs[player] = state
	return state
end

function DigService.SwingShovel(player: Player, playerProfile: any)
	local digState = activeDigs[player]
	if not digState then
		return
	end

	-- Perlawanan 1: Jika Sekop Terlalu Lemah, Item Tidak Bisa Tergali
	if digState.IsTooWeak then
		print(string.format("⚠️ SHOVEL TOO WEAK! DigPower: %d vs MinRequired: %d", digState.ShovelPower, digState.MinDigPower))
		return
	end

	-- Perlawanan 2: Cek Batas Waktu Minigame (Item Hilang jika melebih batas waktu)
	local elapsed = os.clock() - digState.StartTime
	if elapsed > digState.TimeLimit then
		print("⏱️ TIME EXPIRED! Item escaped/destroyed due to resistance.")
		activeDigs[player] = nil
		return
	end

	local now = os.clock()
	local equippedShovelId = playerProfile.Data and playerProfile.Data.EquippedShovel or "WoodenShovel"
	local shovelInfo = Shovels.GetShovel(equippedShovelId)
	if not shovelInfo then
		return
	end

	if (now - digState.LastSwingTime) < shovelInfo.SwingCooldown then
		return
	end

	digState.LastSwingTime = now

	-- Damage Konstan (Tidak ada pengurangan damage/daya gali)
	digState.CurrentHP -= shovelInfo.DigPower

	if digState.CurrentHP <= 0 then
		local item = digState.TargetItem
		local currentCount = playerProfile.Data.Inventory[item.Id] or 0
		playerProfile.Data.Inventory[item.Id] = currentCount + 1

		-- Berikan EXP berdasarkan Rarity Item
		local expGained = LevelConfig.GetEXPFromRarity(item.Rarity)
		LevelService.AddEXP(playerProfile, expGained)

		-- Spawn 3D Model visual effect (Melompat ke atas, jatuh ke belakang player & hilang setelah 2 detik)
		if player.Character then
			DigService.SpawnItemModel(item.Id, player.Character)
		end

		activeDigs[player] = nil
	end
end

function DigService.SpawnItemModel(itemId: string, character: Model): Instance?
	local Debris = game:GetService("Debris")
	local Players = game:GetService("Players")
	local player = Players:GetPlayerFromCharacter(character)

	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return nil
	end

	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if not assets then
		return nil
	end

	local itemsFolder = assets:FindFirstChild("Items")
	if not itemsFolder then
		return nil
	end

	local itemTemplate = itemsFolder:FindFirstChild(itemId)
	if not itemTemplate then
		return nil
	end

	local itemClone = itemTemplate:Clone()

	-- Tentukan Part Utama untuk menerima Impuls Fisika
	local mainPart: BasePart? = nil
	if itemClone:IsA("Model") then
		if not itemClone.PrimaryPart then
			itemClone.PrimaryPart = itemClone:FindFirstChildWhichIsA("BasePart", true)
		end
		mainPart = itemClone.PrimaryPart
	elseif itemClone:IsA("BasePart") then
		mainPart = itemClone
	end

	if not mainPart then
		return nil
	end

	-- Posisikan di BELAKANG KEPALA player (0, 3, 1) agar tidak pernah tersangkut di tubuh player
	local spawnCFrame = hrp.CFrame * CFrame.new(0, 3, 1)
	if itemClone:IsA("Model") then
		itemClone:PivotTo(spawnCFrame)
	else
		mainPart.CFrame = spawnCFrame
	end

	-- Persiapkan physics & ragdoll (Unanchor & aktifkan collision fisik penuh)
	if itemClone:IsA("BasePart") then
		itemClone.Anchored = false
		itemClone.CanCollide = true
	end

	for _, descendant in itemClone:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = true

			if descendant ~= mainPart then
				local existingWeld = descendant:FindFirstChildOfClass("WeldConstraint") or descendant:FindFirstChildOfClass("Weld")
				if not existingWeld then
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = mainPart
					weld.Part1 = descendant
					weld.Parent = descendant
				end
			end
		end
	end

	itemClone.Parent = workspace

	-- Berikan Network Ownership ke Player agar fisika 60 FPS sangat mulus tanpa lag server
	if player then
		pcall(function()
			mainPart:SetNetworkOwner(player)
		end)
	end

	-- Hitung Vektor Lemparan Fisika Ragdoll (Terlempar Melengkung ke Belakang & Berguling di Tanah)
	local lookVector = hrp.CFrame.LookVector
	local upVector = hrp.CFrame.UpVector
	local backwardVector = -lookVector

	local throwVelocity = (upVector * 28) + (backwardVector * 26) + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
	local spinVelocity = Vector3.new(math.random(-15, 15), math.random(-15, 15), math.random(-15, 15))

	mainPart.AssemblyLinearVelocity = throwVelocity
	mainPart.AssemblyAngularVelocity = spinVelocity

	-- Hapus item secara otomatis setelah 2 detik
	Debris:AddItem(itemClone, 2)

	return itemClone
end

return DigService
