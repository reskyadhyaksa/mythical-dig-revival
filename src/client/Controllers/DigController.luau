--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local packagesFolder = ReplicatedStorage:WaitForChild("Packages")
local Roact = require(packagesFolder:WaitForChild("Roact"))

local clientFolder = script.Parent.Parent
local componentsFolder = clientFolder:WaitForChild("Components")
local DigMinigame = require(componentsFolder:WaitForChild("DigMinigame"))

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local startDigRF = remotesFolder:WaitForChild("StartDig") :: RemoteFunction
local swingShovelRF = remotesFolder:WaitForChild("SwingShovel") :: RemoteFunction
local cancelDigRE = remotesFolder:WaitForChild("CancelDig") :: RemoteEvent

local DigController = {}
local currentHandle: any = nil
local isDigMinigameActive = false
local activeInputConnection: RBXScriptConnection? = nil
local onSwingExternalAction: (() -> ())? = nil

function DigController.IsMinigameActive(): boolean
	return isDigMinigameActive
end

function DigController.GetSwingAction(): (() -> ())?
	return onSwingExternalAction
end

function DigController.LockPlayerMovement()
	local player = Players.LocalPlayer
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpHeight = 0
		humanoid.JumpPower = 0
	end
end

function DigController.UnlockPlayerMovement()
	local player = Players.LocalPlayer
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16
		humanoid.JumpHeight = 7.2
		humanoid.JumpPower = 50
	end
end

local function CleanupInputConnection()
	if activeInputConnection then
		activeInputConnection:Disconnect()
		activeInputConnection = nil
	end
end

function DigController.UnmountMinigame()
	CleanupInputConnection()
	onSwingExternalAction = nil
	DigController.UnlockPlayerMovement()

	if currentHandle then
		Roact.unmount(currentHandle)
		currentHandle = nil
	end
end

function DigController.CancelDig()
	if not isDigMinigameActive then
		return
	end
	CleanupInputConnection()
	cancelDigRE:FireServer()
	DigController.UnmountMinigame()
	task.wait(0.15)
	isDigMinigameActive = false
end

function DigController.MountMinigameUI(digData: any, isAutoMode: boolean?)
	if not digData then
		return
	end

	CleanupInputConnection()
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
		DigController.CancelDig()
	end

	local function OnSwingClicked()
		if isTooWeak then
			return
		end

		local updatedState = swingShovelRF:InvokeServer()
		if updatedState then
			if updatedState.IsFinished then
				CleanupInputConnection()

				-- 1. Tampilkan bar 100% penuh sesaat
				DigController.MountComponent(
					rarity,
					0,
					updatedState.MaxHp or maxHp,
					itemName,
					minDigPower,
					shovelPower,
					isTooWeak,
					timeLimit,
					nil,
					nil,
					isAutoMode
				)

				task.wait(0.4)
				DigController.UnmountMinigame()
				task.wait(0.15)
				isDigMinigameActive = false
			else
				DigController.MountComponent(
					rarity,
					updatedState.CurrentHp,
					updatedState.MaxHp,
					itemName,
					minDigPower,
					shovelPower,
					isTooWeak,
					timeLimit,
					OnSwingClicked,
					OnCancelClicked,
					isAutoMode
				)
			end
		else
			DigController.UnmountMinigame()
			task.wait(0.15)
			isDigMinigameActive = false
		end
	end

	onSwingExternalAction = OnSwingClicked

	-- Bebas Klik di layar untuk mengayun sekop manual tanpa mengganggu tombol GUI lain
	activeInputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			OnSwingClicked()
		end
	end)

	DigController.MountComponent(
		rarity,
		currentHp,
		maxHp,
		itemName,
		minDigPower,
		shovelPower,
		isTooWeak,
		timeLimit,
		OnSwingClicked,
		OnCancelClicked,
		isAutoMode
	)
end

function DigController.MountComponent(
	rarity: string,
	currentHp: number,
	maxHp: number,
	itemName: string?,
	minDigPower: number?,
	shovelPower: number?,
	isTooWeak: boolean?,
	timeLimit: number?,
	onSwingCallback: (() -> ())?,
	onCancelCallback: (() -> ())?,
	isAutoMode: boolean?
)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	if not isAutoMode then
		DigController.LockPlayerMovement()
	else
		DigController.UnlockPlayerMovement()
	end

	local element = Roact.createElement(DigMinigame, {
		Rarity = rarity,
		CurrentHp = currentHp,
		MaxHp = maxHp,
		ItemName = itemName or "Node",
		MinDigPower = minDigPower or 5,
		ShovelPower = shovelPower or 10,
		IsTooWeak = isTooWeak or false,
		TimeLimit = timeLimit or 15,
		OnSwing = onSwingCallback,
		OnCancel = onCancelCallback,
	})

	if currentHandle then
		currentHandle = Roact.update(currentHandle, element)
	else
		currentHandle = Roact.mount(element, playerGui, "DigMinigameUI")
	end
end

function DigController.StartDig(luckMultiplier: number?, isAutoMode: boolean?): boolean
	if isDigMinigameActive then
		return false
	end

	local digData = startDigRF:InvokeServer(luckMultiplier)
	if digData then
		DigController.MountMinigameUI(digData, isAutoMode)
		return true
	end
	return false
end

return DigController
