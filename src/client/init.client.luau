--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local Controllers = script.Controllers
local RightMenuController = require(Controllers.RightMenuController) :: any
local DigController = require(Controllers.DigController) :: any
local ShopController = require(Controllers.ShopController) :: any
local InventoryController = require(Controllers.InventoryController) :: any
local StatsHudController = require(Controllers.StatsHudController) :: any
local HotbarController = require(Controllers.HotbarController) :: any

local Store = require(script.Rodux.Store)
local Actions = require(script.Rodux.Actions)

local UserInputService = game:GetService("UserInputService")

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local getPlayerDataRF = remotesFolder:WaitForChild("GetPlayerData") :: RemoteFunction
local startDigRF = remotesFolder:WaitForChild("StartDig") :: RemoteFunction
local swingShovelRF = remotesFolder:WaitForChild("SwingShovel") :: RemoteFunction
local cancelDigRE = remotesFolder:WaitForChild("CancelDig") :: RemoteEvent
local sellItemRE = remotesFolder:WaitForChild("SellItem") :: RemoteEvent
local sellAllRE = remotesFolder:WaitForChild("SellAll") :: RemoteEvent
local buyShovelRE = remotesFolder:WaitForChild("BuyShovel") :: RemoteEvent
local equipShovelRE = remotesFolder:WaitForChild("EquipShovel") :: RemoteEvent
local equipItemRE = remotesFolder:WaitForChild("EquipItem") :: RemoteEvent
local playerDataLoadedRE = remotesFolder:WaitForChild("PlayerDataLoaded") :: RemoteEvent

local activeInputConnection: RBXScriptConnection? = nil

local function CleanupActiveDigConnection()
	if activeInputConnection then
		activeInputConnection:Disconnect()
		activeInputConnection = nil
	end
end

local isInventoryOpen = false
local isShopOpen = false

local function SyncPlayerData(data: any)
	if not data then return end
	Store:dispatch(Actions.SetPlayerData(data))
end

-- Helper untuk mengurus proses Swing dan HP update minigame
local function StartDigMinigameUI(digData: any)
	if not digData then return end

	CleanupActiveDigConnection()

	local currentHp = digData.CurrentHp
	local maxHp = digData.MaxHp
	local rarity = digData.Rarity
	local itemName = digData.ItemName
	local minDigPower = digData.MinDigPower
	local shovelPower = digData.ShovelPower
	local isTooWeak = digData.IsTooWeak
	local timeLimit = digData.TimeLimit

	local function OnCancelClicked()
		CleanupActiveDigConnection()
		cancelDigRE:FireServer()
		DigController.UnmountMinigame()
	end

	local function OnSwingClicked()
		if isTooWeak then return end

		local updatedState = swingShovelRF:InvokeServer()
		if updatedState then
			if updatedState.IsFinished then
				CleanupActiveDigConnection()

				-- 1. Tampilkan bar 100% penuh (CurrentHp = 0)
				DigController.MountMinigame(
					rarity,
					0,
					updatedState.MaxHp or maxHp,
					itemName,
					minDigPower,
					shovelPower,
					isTooWeak,
					timeLimit,
					nil,
					nil
				)

				-- 2. Delay 0.5 detik agar pemain dapat melihat bar 100% selesai sebelum menghilang
				task.wait(0.5)

				DigController.UnmountMinigame()
				task.wait(0.1)
				local newData = getPlayerDataRF:InvokeServer()
				if newData then
					SyncPlayerData(newData)
				end
			else
				DigController.MountMinigame(
					rarity,
					updatedState.CurrentHp,
					updatedState.MaxHp,
					itemName,
					minDigPower,
					shovelPower,
					isTooWeak,
					timeLimit,
					OnSwingClicked,
					OnCancelClicked
				)
			end
		else
			CleanupActiveDigConnection()
			DigController.UnmountMinigame()
		end
	end

	-- Bebas Klik di mana saja di layar (Mouse Click / Screen Touch) untuk mengayun sekop
	activeInputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			OnSwingClicked()
		end
	end)

	DigController.MountMinigame(
		rarity,
		currentHp,
		maxHp,
		itemName,
		minDigPower,
		shovelPower,
		isTooWeak,
		timeLimit,
		OnSwingClicked,
		OnCancelClicked
	)
end

local OnSellItemAction: ((uuidOrItemId: string, amount: number) -> ())? = nil
local OnSellAllAction: (() -> ())? = nil

local function MountOrUpdateInventoryUI(data: any)
	if not data then return end
	SyncPlayerData(data)
	InventoryController.MountInventory(
		OnSellItemAction,
		OnSellAllAction,
		function()
			isInventoryOpen = false
			HotbarController.SetState(nil, false, false)
		end
	)
end

OnSellItemAction = function(uuidOrItemId: string, amount: number)
	sellItemRE:FireServer(uuidOrItemId, amount)
	task.wait(0.1)
	local updatedData = getPlayerDataRF:InvokeServer()
	if updatedData then
		MountOrUpdateInventoryUI(updatedData)
	end
end

OnSellAllAction = function()
	sellAllRE:FireServer()
	task.wait(0.1)
	local updatedData = getPlayerDataRF:InvokeServer()
	if updatedData then
		MountOrUpdateInventoryUI(updatedData)
	end
end

local function ToggleInventory()
	if isInventoryOpen then
		InventoryController.UnmountInventory()
		isInventoryOpen = false
		HotbarController.SetState(nil, false, false)
	else
		local data = getPlayerDataRF:InvokeServer()
		if data then
			if isShopOpen then
				ShopController.UnmountShop()
				isShopOpen = false
			end

			MountOrUpdateInventoryUI(data)
			isInventoryOpen = true
			HotbarController.SetState(nil, true, false)
		end
	end
end

local function MountOrUpdateShopUI(data: any)
	if not data then return end
	SyncPlayerData(data)
	ShopController.MountShop(
		function(shovelId)
			buyShovelRE:FireServer(shovelId)
			task.wait(0.1)
			local updatedData = getPlayerDataRF:InvokeServer()
			if updatedData then
				MountOrUpdateShopUI(updatedData)
			end
		end,
		function(shovelId)
			equipShovelRE:FireServer(shovelId)
			task.wait(0.1)
			local updatedData = getPlayerDataRF:InvokeServer()
			if updatedData then
				MountOrUpdateShopUI(updatedData)
			end
		end,
		function()
			isShopOpen = false
			HotbarController.SetState(nil, false, false)
		end
	)
end

local function ToggleShop()
	if isShopOpen then
		ShopController.UnmountShop()
		isShopOpen = false
		HotbarController.SetState(nil, false, false)
	else
		local data = getPlayerDataRF:InvokeServer()
		if data then
			if isInventoryOpen then
				InventoryController.UnmountInventory()
				isInventoryOpen = false
			end

			MountOrUpdateShopUI(data)
			isShopOpen = true
			HotbarController.SetState(nil, false, true)
		end
	end
end

local function ToggleShovel()
	local char = LocalPlayer.Character
	if not char then return end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local equippedTool = char:FindFirstChildOfClass("Tool")

	if equippedTool and humanoid then
		humanoid:UnequipTools()
		HotbarController.SetState(false, nil, nil)
	else
		local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
		local tool = backpack and backpack:FindFirstChildOfClass("Tool")
		if tool and humanoid then
			humanoid:EquipTool(tool)
			HotbarController.SetState(true, nil, nil)
		else
			local data = getPlayerDataRF:InvokeServer()
			if data and data.EquippedShovel then
				equipShovelRE:FireServer(data.EquippedShovel)
				task.wait(0.15)
				local newTool = backpack and backpack:FindFirstChildOfClass("Tool")
				if newTool and humanoid then
					humanoid:EquipTool(newTool)
					HotbarController.SetState(true, nil, nil)
				end
			end
		end
	end
end

local function OnEquipItem(uuid: string, itemId: string)
	local char = LocalPlayer.Character
	if not char then return end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local equippedTool = char:FindFirstChildOfClass("Tool")

	if equippedTool and (equippedTool.Name == itemId or equippedTool.Name == uuid) and humanoid then
		humanoid:UnequipTools()
		HotbarController.SetState(false, nil, nil, "", "")
	else
		equipItemRE:FireServer(itemId)
		HotbarController.SetState(false, nil, nil, itemId, uuid)
	end
end

-- Monitor karakter untuk highlight status Sekop / Item di Hotbar
local function SetupToolTracker(char: Model)
	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			if child.Name:find("Shovel") or child.Name:find("Sekop") then
				HotbarController.SetState(true, nil, nil, "")
			else
				HotbarController.SetState(false, nil, nil, child.Name)
			end
		end
	end)
	char.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			HotbarController.SetState(false, nil, nil, "")
		end
	end)

	local currentTool = char:FindFirstChildOfClass("Tool")
	if currentTool then
		if currentTool.Name:find("Shovel") or currentTool.Name:find("Sekop") then
			HotbarController.SetState(true, nil, nil, "")
		else
			HotbarController.SetState(false, nil, nil, currentTool.Name)
		end
	end
end

if LocalPlayer.Character then
	SetupToolTracker(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(SetupToolTracker)

local function SetupHUD()
	-- Mount Stats HUD (Coins & Luck) langsung di awal agar selalu muncul tanpa delay
	StatsHudController.MountStatsHud()

	-- Mount Hotbar kustom
	HotbarController.MountHotbar(
		ToggleShovel,
		ToggleInventory,
		ToggleShop,
		OnEquipItem
	)

	-- Ambil data aktual dari server DataStore secara asinkron
	task.spawn(function()
		local initialData = getPlayerDataRF:InvokeServer()
		if initialData then
			SyncPlayerData(initialData)
		end
	end)
end

-- Server push: saat server selesai memuat profile data player, langsung sinkronkan ke client
playerDataLoadedRE.OnClientEvent:Connect(function(data)
	if data then
		SyncPlayerData(data)
	end
end)

-- 2. Memulai Penggalian saat player mengayun sekop
local function ConnectToolDigging(character: Model)
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			child.Activated:Connect(function()
				local digData = startDigRF:InvokeServer()
				StartDigMinigameUI(digData)
			end)
		end
	end)

	local currentTool = character:FindFirstChildOfClass("Tool")
	if currentTool then
		currentTool.Activated:Connect(function()
			local digData = startDigRF:InvokeServer()
			StartDigMinigameUI(digData)
		end)
	end
end

if LocalPlayer.Character then
	ConnectToolDigging(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(ConnectToolDigging)

SetupHUD()

print("🚀 Client initialized! SideMenu HUD & Digging triggers active.")
