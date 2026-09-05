--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local clientFolder = script.Parent.Parent
local roduxFolder = clientFolder:WaitForChild("Rodux")
local Store = require(roduxFolder:WaitForChild("Store"))

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local equipShovelRE = remotesFolder:WaitForChild("EquipShovel") :: RemoteEvent
local equipItemRE = remotesFolder:WaitForChild("EquipItem") :: RemoteEvent

local Controllers = clientFolder:WaitForChild("Controllers")
local HotbarController = require(Controllers:WaitForChild("HotbarController")) :: any
local DigController = require(Controllers:WaitForChild("DigController")) :: any
local AutoDigController = require(Controllers:WaitForChild("AutoDigController")) :: any
local HoldPowerController = require(Controllers:WaitForChild("HoldPowerController")) :: any

local ToolController = {}

-- Animation IDs
local HOLD_ID = "rbxassetid://83280084981203"
local DIG_ID = "rbxassetid://74513157448342"

local holdTrack: AnimationTrack? = nil
local digTrack: AnimationTrack? = nil
local currentMotor: Motor6D? = nil
local toolActivatedConn: RBXScriptConnection? = nil
local toolUnequippedConn: RBXScriptConnection? = nil

-- Helper to create and load an animation
local function loadTrack(animator: Animator, assetId: string, priority: Enum.AnimationPriority, looped: boolean): AnimationTrack?
	local anim = Instance.new("Animation")
	anim.AnimationId = assetId

	local success, track = pcall(function()
		return animator:LoadAnimation(anim)
	end)

	if success and track then
		track.Priority = priority
		track.Looped = looped
		return track
	end
	return nil
end

local function StopShovelAnimations()
	-- Stop and clean up tracks
	if holdTrack then
		holdTrack:Stop()
		holdTrack:Destroy()
		holdTrack = nil
	end

	if digTrack then
		digTrack:Stop()
		digTrack:Destroy()
		digTrack = nil
	end

	-- Detach shovel
	if currentMotor then
		currentMotor.Part0 = nil
		currentMotor = nil
	end

	if toolActivatedConn then
		toolActivatedConn:Disconnect()
		toolActivatedConn = nil
	end

	if toolUnequippedConn then
		toolUnequippedConn:Disconnect()
		toolUnequippedConn = nil
	end
end

local currentSwingToken = 0

function ToolController.StartMinigameDigLoop(speed: number?)
	local idleSpeed = speed or 0.35
	if digTrack then
		digTrack.Looped = true
		if not digTrack.IsPlaying then
			digTrack:Play(0.15, 1, idleSpeed)
		else
			digTrack:AdjustSpeed(idleSpeed)
		end
	end
end

function ToolController.PlayDigSwing(speed: number?)
	local swingSpeed = speed or 1.3
	currentSwingToken += 1
	local thisToken = currentSwingToken

	if digTrack then
		digTrack.Looped = true
		if not digTrack.IsPlaying then
			digTrack:Play(0.05, 1, swingSpeed)
		else
			digTrack:AdjustSpeed(swingSpeed)
		end

		task.spawn(function()
			task.wait(0.35)
			-- Kembalikan ke kecepatan lambat idle loop jika minigame masih berlangsung dan belum ada tap baru
			if thisToken == currentSwingToken and DigController.IsMinigameActive() and digTrack and digTrack.IsPlaying then
				digTrack:AdjustSpeed(0.35)
			end
		end)
	end
end

function ToolController.StopMinigameDigLoop()
	currentSwingToken += 1
	if digTrack then
		digTrack.Looped = false
		digTrack:Stop(0.2)
	end
	if holdTrack and not holdTrack.IsPlaying then
		holdTrack:Play(0.2)
	end
end

function ToolController.PlayDigAnimation()
	ToolController.PlayDigSwing()
end

local function PlayShovelHoldAnimation(char: Model, shovelInstance: Instance)
	StopShovelAnimations()

	if shovelInstance:IsA("Tool") then
		(shovelInstance :: Tool).RequiresHandle = false
	end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local arm = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightHand") or char:FindFirstChild("RightArm")

	local handle = shovelInstance:FindFirstChild("Handle") :: BasePart?
	if not handle and shovelInstance:IsA("Model") then
		handle = (shovelInstance :: Model).PrimaryPart or shovelInstance:FindFirstChildWhichIsA("BasePart", true)
	end
	if not handle then
		handle = shovelInstance:FindFirstChildWhichIsA("BasePart", true)
	end

	if not arm or not handle or not humanoid then
		return
	end

	-- Unanchor semua part di dalam sekop agar tidak tertinggal di koordinat (0,0,0) / ghaib
	for _, desc in shovelInstance:GetDescendants() do
		if desc:IsA("BasePart") then
			desc.Anchored = false
			desc.CanCollide = false
		end
	end

	-- Disable default Roblox grip so it doesn't fight the Motor6D
	task.defer(function()
		local rightGrip = arm:FindFirstChild("RightGrip") or (handle and handle:FindFirstChild("RightGrip"))
		if rightGrip and (rightGrip:IsA("Weld") or rightGrip:IsA("ManualWeld")) then
			(rightGrip :: any).Enabled = false
		end
	end)

	-- Cari atau buat Motor6D di Handle
	local motor: Motor6D? = handle:FindFirstChild("Motor6D") :: Motor6D?
	if not motor then
		motor = handle:FindFirstChildOfClass("Motor6D")
	end
	if not motor then
		for _, desc in shovelInstance:GetDescendants() do
			if desc:IsA("Motor6D") then
				motor = desc
				break
			end
		end
	end

	if not motor then
		local newMotor = Instance.new("Motor6D")
		newMotor.Name = "Motor6D"
		newMotor.Parent = handle
		motor = newMotor
	end

	if motor then
		motor.Part1 = handle
		motor.Part0 = arm :: BasePart
		currentMotor = motor
	end

	-- Get or create Animator
	local animator = humanoid:FindFirstChildOfClass("Animator") :: Animator?
	if not animator then
		local newAnimator = Instance.new("Animator")
		newAnimator.Parent = humanoid
		animator = newAnimator
	end

	if animator then
		-- Clear/stop old animations from previous versions / default pose
		for _, playingTrack in animator:GetPlayingAnimationTracks() do
			if playingTrack.Name:lower():find("tool") or (playingTrack.Animation and (playingTrack.Animation.AnimationId:find("182393478") or playingTrack.Animation.AnimationId:find("94499608380435"))) then
				playingTrack:Stop()
				playingTrack:Destroy()
			end
		end

		-- Load tracks (Hold = Action, Dig = Action2 to override hold cleanly)
		holdTrack = loadTrack(animator, HOLD_ID, Enum.AnimationPriority.Action, true)
		digTrack = loadTrack(animator, DIG_ID, Enum.AnimationPriority.Action2, false)

		-- Start idle hold animation
		if holdTrack then
			holdTrack:Play()
		end
	end

	-- Tool Activated & Unequipped listeners
	if shovelInstance:IsA("Tool") then
		local tool = shovelInstance :: Tool
		toolActivatedConn = tool.Activated:Connect(function()
			-- Animasi digging tidak boleh berjalan saat hold, hanya aktif saat minigame berjalan
			if DigController.IsMinigameActive() and not HoldPowerController.IsHolding() then
				ToolController.PlayDigAnimation()
			end
		end)
		toolUnequippedConn = tool.Unequipped:Connect(function()
			StopShovelAnimations()
		end)
	end
end

function ToolController.GetCurrentEquippedTool(): Instance?
	local char = Players.LocalPlayer.Character
	if not char then return nil end
	for _, child in char:GetChildren() do
		if (child:IsA("Tool") or child:IsA("Model")) and (child.Name:find("Shovel") ~= nil or child.Name:find("Sekop") ~= nil) then
			return child
		end
	end
	return char:FindFirstChildOfClass("Tool")
end

function ToolController.IsHoldingShovel(): boolean
	local tool = ToolController.GetCurrentEquippedTool()
	return tool ~= nil and (tool.Name:find("Shovel") ~= nil or tool.Name:find("Sekop") ~= nil)
end

function ToolController.ToggleShovel()
	if DigController.IsMinigameActive() then
		return
	end

	local localPlayer = Players.LocalPlayer
	local char = localPlayer.Character
	if not char then
		return
	end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local equippedTool = ToolController.GetCurrentEquippedTool()
	local isHoldingShovel = equippedTool and (equippedTool.Name:find("Shovel") ~= nil or equippedTool.Name:find("Sekop") ~= nil)

	if isHoldingShovel and humanoid then
		humanoid:UnequipTools()
		if equippedTool and equippedTool:IsA("Model") then
			equippedTool:Destroy()
		end
		StopShovelAnimations()
		HotbarController.SetState(false, nil, nil, "", "")
	else
		if equippedTool and humanoid then
			humanoid:UnequipTools()
			if equippedTool:IsA("Model") then
				equippedTool:Destroy()
			end
		end

		local backpack = localPlayer:FindFirstChildOfClass("Backpack")
		if backpack then
			for _, tool in backpack:GetChildren() do
				if not tool.Name:find("Shovel") and not tool.Name:find("Sekop") then
					tool:Destroy()
				end
			end
		end

		local shovelTool: Instance? = nil
		if backpack then
			for _, child in backpack:GetChildren() do
				if (child:IsA("Tool") or child:IsA("Model")) and (child.Name:find("Shovel") or child.Name:find("Sekop")) then
					shovelTool = child
					break
				end
			end
		end

		if shovelTool and humanoid then
			if shovelTool:IsA("Tool") then
				humanoid:EquipTool(shovelTool :: Tool)
			else
				shovelTool.Parent = char
			end
			HotbarController.SetState(true, nil, nil, "", "")
		else
			local state = Store:getState()
			local shovelId = (state and state.EquippedShovel) or "WoodenShovel"
			equipShovelRE:FireServer(shovelId)
			task.wait(0.15)
			if backpack and humanoid then
				for _, child in backpack:GetChildren() do
					if (child:IsA("Tool") or child:IsA("Model")) and (child.Name:find("Shovel") or child.Name:find("Sekop")) then
						if child:IsA("Tool") then
							humanoid:EquipTool(child :: Tool)
						else
							child.Parent = char
						end
						HotbarController.SetState(true, nil, nil, "", "")
						break
					end
				end
			end
		end
	end
end

function ToolController.OnEquipItem(uuid: string, itemId: string)
	if DigController.IsMinigameActive() then
		return
	end

	local localPlayer = Players.LocalPlayer
	local char = localPlayer.Character
	if not char then
		return
	end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local equippedTool = char:FindFirstChildOfClass("Tool")
	local currentToolUuid = equippedTool and equippedTool:GetAttribute("UUID")

	if
		equippedTool
		and ((uuid ~= "" and currentToolUuid == uuid) or (uuid == "" and equippedTool.Name == itemId))
		and humanoid
	then
		humanoid:UnequipTools()
		local backpack = localPlayer:FindFirstChildOfClass("Backpack")
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

function ToolController.SetupToolTracker(char: Model)
	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") or child.Name:find("Shovel") or child.Name:find("Sekop") then
			if child.Name:find("Shovel") or child.Name:find("Sekop") then
				HotbarController.SetState(true, nil, nil, "", "")
				PlayShovelHoldAnimation(char, child)
			else
				local toolUuid = child:GetAttribute("UUID") or ""
				HotbarController.SetState(false, nil, nil, child.Name, toolUuid)
			end
		end
	end)

	char.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") or child.Name:find("Shovel") or child.Name:find("Sekop") then
			if child.Name:find("Shovel") or child.Name:find("Sekop") then
				StopShovelAnimations()
			end
			HotbarController.SetState(false, nil, nil, "", "")
		end
	end)

	local currentTool = ToolController.GetCurrentEquippedTool()
	if currentTool then
		if currentTool.Name:find("Shovel") or currentTool.Name:find("Sekop") then
			HotbarController.SetState(true, nil, nil, "", "")
			PlayShovelHoldAnimation(char, currentTool)
		else
			local toolUuid = currentTool:GetAttribute("UUID") or ""
			HotbarController.SetState(false, nil, nil, currentTool.Name, toolUuid)
		end
	end
end

function ToolController.Init()
	local localPlayer = Players.LocalPlayer

	if localPlayer.Character then
		ToolController.SetupToolTracker(localPlayer.Character)
	end
	localPlayer.CharacterAdded:Connect(ToolController.SetupToolTracker)

	-- Listener Input Hold Charge pada Sekop
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if DigController.IsMinigameActive() or AutoDigController.IsActive() then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if ToolController.IsHoldingShovel() then
				HoldPowerController.StartHold(function(multiplier)
					DigController.StartDig(multiplier)
				end)
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if HoldPowerController.IsHolding() then
				HoldPowerController.ReleaseHold()
			end
		end
	end)
end

return ToolController
