--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. Inisialisasi Rodux State Management
local clientFolder = script
local roduxFolder = clientFolder:WaitForChild("Rodux")
local Store = require(roduxFolder:WaitForChild("Store"))
local Actions = require(roduxFolder:WaitForChild("Actions"))

-- 2. Import Modular Controllers
local Controllers = clientFolder:WaitForChild("Controllers")
local StatsHudController = require(Controllers:WaitForChild("StatsHudController")) :: any
local HotbarController = require(Controllers:WaitForChild("HotbarController")) :: any
-- local RightMenuController = require(Controllers:WaitForChild("RightMenuController")) :: any
local CompassController = require(Controllers:WaitForChild("CompassController")) :: any
local HoldPowerController = require(Controllers:WaitForChild("HoldPowerController")) :: any
local DigController = require(Controllers:WaitForChild("DigController")) :: any
local AutoDigController = require(Controllers:WaitForChild("AutoDigController")) :: any
local ToolController = require(Controllers:WaitForChild("ToolController")) :: any
local InventoryController = require(Controllers:WaitForChild("InventoryController")) :: any
local ShopController = require(Controllers:WaitForChild("ShopController")) :: any
local MobileDigController = require(Controllers:WaitForChild("MobileDigController")) :: any

-- 3. Remotes
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local getPlayerDataRF = remotesFolder:WaitForChild("GetPlayerData") :: RemoteFunction
local playerDataLoadedRE = remotesFolder:WaitForChild("PlayerDataLoaded") :: RemoteEvent

local function SyncPlayerData(data: any)
	if not data then
		return
	end
	Store:dispatch(Actions.SetPlayerData(data))
end

-- 4. Sinkronisasi Reaktif Store -> UI
Store.changed:connect(function(state)
	StatsHudController.MountStatsHud(state.Coins, state.Luck)
	if InventoryController.IsOpen() then
		InventoryController.MountOrUpdate()
	end
	if ShopController.IsOpen() then
		ShopController.MountOrUpdate()
	end
	MobileDigController.Update()
end)

-- 5. Mount Initial HUDs
StatsHudController.MountStatsHud()
HoldPowerController.MountHoldBar()
CompassController.MountCompass()
MobileDigController.Mount()

HotbarController.MountHotbar(
	ToolController.ToggleShovel,
	InventoryController.Toggle,
	ShopController.Toggle,
	ToolController.OnEquipItem,
	AutoDigController.ToggleAutoDig
)

-- RightMenuController.MountRightMenu(
-- 	InventoryController.Toggle,
-- 	ShopController.Toggle
-- )

-- 6. Inisialisasi Tool & Input Lifecycle
ToolController.Init()

-- 7. Load & Listen Player Data Store
local initialData = getPlayerDataRF:InvokeServer()
if initialData then
	SyncPlayerData(initialData)
end

playerDataLoadedRE.OnClientEvent:Connect(function(data)
	SyncPlayerData(data)
end)

print("🚀 Mythic Dig Client Initialized (Modular Clean Architecture)!")
