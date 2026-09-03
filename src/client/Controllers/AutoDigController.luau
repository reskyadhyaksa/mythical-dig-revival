--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local clientFolder = script.Parent.Parent
local roduxFolder = clientFolder:WaitForChild("Rodux")
local Store = require(roduxFolder:WaitForChild("Store"))

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local dataFolder = sharedFolder:WaitForChild("Data")
local commonFolder = sharedFolder:WaitForChild("Common")
local LevelConfig = require(dataFolder:WaitForChild("LevelConfig")) :: any
local PowerBarHelper = require(commonFolder:WaitForChild("PowerBarHelper")) :: any

local Controllers = clientFolder:WaitForChild("Controllers")
local HotbarController = require(Controllers:WaitForChild("HotbarController")) :: any
local HoldPowerController = require(Controllers:WaitForChild("HoldPowerController")) :: any
local DigController = require(Controllers:WaitForChild("DigController")) :: any

local AutoDigController = {}
local isAutoDigActive = false
local autoStartPos: Vector3? = nil

function AutoDigController.IsActive(): boolean
	return isAutoDigActive
end

function AutoDigController.StopAutoDig()
	if not isAutoDigActive then
		return
	end
	isAutoDigActive = false
	autoStartPos = nil
	HotbarController.SetAutoState(false)
	HoldPowerController.Update(0, 1.0, false)

	if DigController.IsMinigameActive() then
		DigController.CancelDig()
	end
end

function AutoDigController.StartAutoDig()
	local localPlayer = Players.LocalPlayer
	local char = localPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end

	-- Cek kapasitas tas sebelum memulai auto
	local state = Store:getState()
	local lvl = state and state.Level or 0
	local maxCap = LevelConfig.GetMaxInventoryCapacity(lvl)
	local invCount = #(state and state.Inventory or {})
	if invCount >= maxCap then
		print("⚠️ Cannot start Auto: Inventory Full!")
		return
	end

	isAutoDigActive = true
	autoStartPos = hrp.Position
	HotbarController.SetAutoState(true)

	-- Pastikan sekop ter-equip
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local equippedTool = char:FindFirstChildOfClass("Tool")
	if not (equippedTool and (equippedTool.Name:find("Shovel") or equippedTool.Name:find("Sekop"))) then
		local backpack = localPlayer:FindFirstChildOfClass("Backpack")
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

	-- Jalankan Loop Auto Mining
	task.spawn(function()
		while isAutoDigActive do
			local currentCharacter = localPlayer.Character
			local currentHrp = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart") :: BasePart?

			-- 1. Toleransi jarak 10 studs
			local startPos = autoStartPos
			if not currentHrp or not startPos or (currentHrp.Position - startPos).Magnitude > 10 then
				AutoDigController.StopAutoDig()
				break
			end

			-- 2. Pengecekan kapasitas tas saat auto berjalan
			local currentState = Store:getState()
			local currentLevel = currentState and currentState.Level or 0
			local currentMaxCap = LevelConfig.GetMaxInventoryCapacity(currentLevel)
			local currentInvCount = #(currentState and currentState.Inventory or {})
			if currentInvCount >= currentMaxCap then
				AutoDigController.StopAutoDig()
				break
			end

			-- 3. Jika minigame belum aktif, mulai simulasi hold power random tersinkronisasi dengan SWEEP_SPEED
			if not DigController.IsMinigameActive() then
				local targetProgress = math.random(30, 85) / 100
				local sweepSpeed = HoldPowerController.SWEEP_SPEED or 0.9
				local chargeDuration = math.max(0.05, targetProgress * sweepSpeed)
				local startT = os.clock()

				HoldPowerController.Update(0, 1.0, true)
				while isAutoDigActive and not DigController.IsMinigameActive() and (os.clock() - startT) < chargeDuration do
					local p = math.clamp((os.clock() - startT) / chargeDuration, 0, 1) * targetProgress
					local mult = 1.0 + (p * 1.5)
					HoldPowerController.Update(p, mult, true)
					task.wait(0.03)
				end

				if not isAutoDigActive then
					HoldPowerController.Update(0, 1.0, false)
					break
				end

				local tier = PowerBarHelper.GetLuckTier(targetProgress)
				HoldPowerController.Update(0, 1.0, false)
				if targetProgress >= 0.20 and localPlayer.Character then
					HoldPowerController.ShowLuckPopup(localPlayer.Character, tier.Name .. "!", tier.Color)
				end

				local success = DigController.StartDig(tier.Multiplier, true)
				if not success then
					task.wait(0.5)
				end
			else
				-- Jika minigame sedang aktif, ayun sekop secara otomatis (auto-clicker)
				task.wait(0.25)
				local swingAction = DigController.GetSwingAction()
				if isAutoDigActive and DigController.IsMinigameActive() and swingAction then
					swingAction()
				end
			end

			task.wait(0.1)
		end
	end)
end

function AutoDigController.ToggleAutoDig()
	if isAutoDigActive then
		AutoDigController.StopAutoDig()
	else
		AutoDigController.StartAutoDig()
	end
end

-- Monitor jarak 10 studs setiap frame agar deteksi pergerakan instan
RunService.Heartbeat:Connect(function()
	local startPos = autoStartPos
	if isAutoDigActive and startPos then
		local char = Players.LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp and (hrp.Position - startPos).Magnitude > 10 then
			AutoDigController.StopAutoDig()
		end
	end
end)

return AutoDigController
