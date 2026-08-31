--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local Controllers = script.Controllers
local SideMenuController = require(Controllers.SideMenuController) :: any
local DigController = require(Controllers.DigController) :: any
local ShopController = require(Controllers.ShopController) :: any
local InventoryController = require(Controllers.InventoryController) :: any

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

local activeInputConnection: RBXScriptConnection? = nil

local function CleanupActiveDigConnection()
	if activeInputConnection then
		activeInputConnection:Disconnect()
		activeInputConnection = nil
	end
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
				DigController.UnmountMinigame()
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

-- 1. Tampilkan Side Menu (HUD Kiri Layar) secara otomatis saat Client berjalan
local function SetupHUD()
	SideMenuController.MountSideMenu(
		function()
			-- Callback Tombol Inventory (BAG)
			local data = getPlayerDataRF:InvokeServer()
			if data then
				InventoryController.MountInventory(
					data.Inventory or {},
					data.Level or 0,
					data.Coins or 0,
					function(itemId, amount)
						sellItemRE:FireServer(itemId, amount)
						task.wait(0.1)
						-- Refresh Inventory UI
						local updatedData = getPlayerDataRF:InvokeServer()
						if updatedData then
							InventoryController.MountInventory(
								updatedData.Inventory or {},
								updatedData.Level or 0,
								updatedData.Coins or 0,
								nil,
								nil
							)
						end
					end,
					function()
						sellAllRE:FireServer()
						task.wait(0.1)
						-- Refresh Inventory UI
						local updatedData = getPlayerDataRF:InvokeServer()
						if updatedData then
							InventoryController.MountInventory(
								updatedData.Inventory or {},
								updatedData.Level or 0,
								updatedData.Coins or 0,
								nil,
								nil
							)
						end
					end
				)
			end
		end,
		function()
			-- Callback Tombol Shop (SHOP)
			local data = getPlayerDataRF:InvokeServer()
			if data then
				ShopController.MountShop(
					data.Coins or 0,
					data.EquippedShovel or "WoodenShovel",
					data.OwnedShovels or { "WoodenShovel" },
					function(shovelId)
						buyShovelRE:FireServer(shovelId)
						task.wait(0.1)
						-- Refresh Shop UI
						local updatedData = getPlayerDataRF:InvokeServer()
						if updatedData then
							ShopController.MountShop(
								updatedData.Coins or 0,
								updatedData.EquippedShovel or "WoodenShovel",
								updatedData.OwnedShovels or { "WoodenShovel" },
								nil,
								nil
							)
						end
					end,
					function(shovelId)
						equipShovelRE:FireServer(shovelId)
						task.wait(0.1)
						-- Refresh Shop UI
						local updatedData = getPlayerDataRF:InvokeServer()
						if updatedData then
							ShopController.MountShop(
								updatedData.Coins or 0,
								updatedData.EquippedShovel or "WoodenShovel",
								updatedData.OwnedShovels or { "WoodenShovel" },
								nil,
								nil
							)
						end
					end
				)
			end
		end
	)
end

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
