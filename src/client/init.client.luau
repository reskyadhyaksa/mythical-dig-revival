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
local isDigMinigameActive = false

local function SyncPlayerData(data: any)
	if not data then return end
	Store:dispatch(Actions.SetPlayerData(data))
end

-- Helper untuk mengurus proses Swing dan HP update minigame
local function StartDigMinigameUI(digData: any)
	if not digData then return end

	CleanupActiveDigConnection()
	isDigMinigameActive = true

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
		task.wait(0.15)
		isDigMinigameActive = false
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
				task.wait(0.2) -- Delay pendingin setelah UI minigame hilang sepenuhnya

				local newData = getPlayerDataRF:InvokeServer()
				if newData then
					SyncPlayerData(newData)
				end

				isDigMinigameActive = false
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
			task.wait(0.15)
			isDigMinigameActive = false
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

local function MountOrUpdateInventoryUI()
	InventoryController.MountInventory(
		OnSellItemAction,
		OnSellAllAction,
		function()
			isInventoryOpen = false
			HotbarController.SetState(nil, false, false)
		end
	)
end

local function MountOrUpdateShopUI()
	ShopController.MountShop(
		function(shovelId)
			buyShovelRE:FireServer(shovelId)
			task.wait(0.1)
			local updatedData = getPlayerDataRF:InvokeServer()
			if updatedData then
				SyncPlayerData(updatedData)
			end
		end,
		function(shovelId)
			equipShovelRE:FireServer(shovelId)
			task.wait(0.1)
			local updatedData = getPlayerDataRF:InvokeServer()
			if updatedData then
				SyncPlayerData(updatedData)
			end
		end,
		function()
			isShopOpen = false
			HotbarController.SetState(nil, false, false)
		end
	)
end

-- Store.changed: Otomatis memicu update reaktif pada StatsHud, Hotbar, Inventory, dan Shop
Store.changed:connect(function(newState)
	StatsHudController.MountStatsHud(newState.Coins, newState.Luck)
	HotbarController.SetInventory(newState.Inventory)

	if isInventoryOpen then
		MountOrUpdateInventoryUI()
	end
	if isShopOpen then
		MountOrUpdateShopUI()
	end
end)

OnSellItemAction = function(uuidOrItemId: string, amount: number)
	sellItemRE:FireServer(uuidOrItemId, amount)
	task.wait(0.1)
	local updatedData = getPlayerDataRF:InvokeServer()
	if updatedData then
		SyncPlayerData(updatedData)
	end
end

OnSellAllAction = function()
	sellAllRE:FireServer()
	task.wait(0.1)
	local updatedData = getPlayerDataRF:InvokeServer()
	if updatedData then
		SyncPlayerData(updatedData)
	end
end

local function ToggleInventory()
	if isDigMinigameActive then return end

	if isInventoryOpen then
		InventoryController.UnmountInventory()
		isInventoryOpen = false
		HotbarController.SetState(nil, false, false)
	else
		local data = getPlayerDataRF:InvokeServer()
		if data then
			SyncPlayerData(data)
			if isShopOpen then
				ShopController.UnmountShop()
				isShopOpen = false
			end

			MountOrUpdateInventoryUI()
			isInventoryOpen = true
			HotbarController.SetState(nil, true, false)
		end
	end
end

local function ToggleShop()
	if isDigMinigameActive then return end

	if isShopOpen then
		ShopController.UnmountShop()
		isShopOpen = false
		HotbarController.SetState(nil, false, false)
	else
		local data = getPlayerDataRF:InvokeServer()
		if data then
			SyncPlayerData(data)
			if isInventoryOpen then
				InventoryController.UnmountInventory()
				isInventoryOpen = false
			end

			MountOrUpdateShopUI()
			isShopOpen = true
			HotbarController.SetState(nil, false, true)
		end
	end
end

local function ToggleShovel()
	if isDigMinigameActive then return end

	local char = LocalPlayer.Character
	if not char then return end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local equippedTool = char:FindFirstChildOfClass("Tool")

	-- Cek apakah karakter sedang memegang sekop
	local isHoldingShovel = equippedTool and (equippedTool.Name:find("Shovel") ~= nil or equippedTool.Name:find("Sekop") ~= nil)

	if isHoldingShovel and humanoid then
		-- Jika sedang memegang sekop, unequip sekop
		humanoid:UnequipTools()
		HotbarController.SetState(false, nil, nil, "", "")
	else
		-- Jika sedang memegang item non-sekop, unequip dulu
		if equippedTool and humanoid then
			humanoid:UnequipTools()
		end

		-- Bersihkan tool item visual non-sekop dari backpack agar tidak terpilih
		local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
		if backpack then
			for _, tool in backpack:GetChildren() do
				if not tool.Name:find("Shovel") and not tool.Name:find("Sekop") then
					tool:Destroy()
				end
			end
		end

		-- Cari sekop di dalam backpack
		local shovelTool: Tool? = nil
		if backpack then
			for _, child in backpack:GetChildren() do
				if child:IsA("Tool") and (child.Name:find("Shovel") or child.Name:find("Sekop")) then
					shovelTool = child
					break
				end
			end
		end

		if shovelTool and humanoid then
			humanoid:EquipTool(shovelTool)
			HotbarController.SetState(true, nil, nil, "", "")
		else
			local state = Store:getState()
			local shovelId = (state and state.EquippedShovel) or "WoodenShovel"
			equipShovelRE:FireServer(shovelId)
			task.wait(0.15)
			if backpack and humanoid then
				for _, child in backpack:GetChildren() do
					if child:IsA("Tool") and (child.Name:find("Shovel") or child.Name:find("Sekop")) then
						humanoid:EquipTool(child)
						HotbarController.SetState(true, nil, nil, "", "")
						break
					end
				end
			end
		end
	end
end

local function OnEquipItem(uuid: string, itemId: string)
	if isDigMinigameActive then return end

	local char = LocalPlayer.Character
	if not char then return end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local equippedTool = char:FindFirstChildOfClass("Tool")
	local currentToolUuid = equippedTool and equippedTool:GetAttribute("UUID")

	-- Jika item yang sama diklik kembali, unequip item tersebut dan bersihkan dari backpack
	if equippedTool and ((uuid ~= "" and currentToolUuid == uuid) or (uuid == "" and equippedTool.Name == itemId)) and humanoid then
		humanoid:UnequipTools()
		local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
		if backpack then
			for _, tool in backpack:GetChildren() do
				if not tool.Name:find("Shovel") and not tool.Name:find("Sekop") then
					tool:Destroy()
				end
			end
		end
		HotbarController.SetState(false, nil, nil, "", "")
	else
		equipItemRE:FireServer(itemId, uuid)
		HotbarController.SetState(false, nil, nil, itemId, uuid)
	end
end

-- Monitor karakter untuk highlight status Sekop / Item di Hotbar
local function SetupToolTracker(char: Model)
	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			if child.Name:find("Shovel") or child.Name:find("Sekop") then
				HotbarController.SetState(true, nil, nil, "", "")
			else
				local toolUuid = child:GetAttribute("UUID") or ""
				HotbarController.SetState(false, nil, nil, child.Name, toolUuid)
			end
		end
	end)
	char.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			HotbarController.SetState(false, nil, nil, "", "")
		end
	end)

	local currentTool = char:FindFirstChildOfClass("Tool")
	if currentTool then
		if currentTool.Name:find("Shovel") or currentTool.Name:find("Sekop") then
			HotbarController.SetState(true, nil, nil, "", "")
		else
			local toolUuid = currentTool:GetAttribute("UUID") or ""
			HotbarController.SetState(false, nil, nil, currentTool.Name, toolUuid)
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

	-- Mount Right Sidebar Menu (Inventory & Shop)
	RightMenuController.MountRightMenu(
		ToggleInventory,
		ToggleShop
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
	local function OnToolActivated(tool: Tool)
		if isDigMinigameActive then return end
		if not tool.Name:find("Shovel") and not tool.Name:find("Sekop") then return end

		local digData = startDigRF:InvokeServer()
		if digData then
			StartDigMinigameUI(digData)
		end
	end

	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			child.Activated:Connect(function()
				OnToolActivated(child)
			end)
		end
	end)

	local currentTool = character:FindFirstChildOfClass("Tool")
	if currentTool then
		currentTool.Activated:Connect(function()
			OnToolActivated(currentTool)
		end)
	end
end

if LocalPlayer.Character then
	ConnectToolDigging(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(ConnectToolDigging)

SetupHUD()

print("🚀 Client initialized! SideMenu HUD & Digging triggers active.")
