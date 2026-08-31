--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.Roact)
local DigMinigame = require(script.Parent.Parent.Components.DigMinigame)

local DigUIController = {}
local currentHandle: any = nil

function DigUIController.LockPlayerMovement()
	local player = Players.LocalPlayer
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	humanoid.WalkSpeed = 0
	humanoid.JumpHeight = 0
	humanoid.JumpPower = 0
end

function DigUIController.UnlockPlayerMovement()
	local player = Players.LocalPlayer
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	humanoid.WalkSpeed = 16
	humanoid.JumpHeight = 7.2
	humanoid.JumpPower = 50
end

function DigUIController.MountMinigame(
	rarity: string,
	currentHp: number,
	maxHp: number,
	itemName: string?,
	minDigPower: number?,
	shovelPower: number?,
	isTooWeak: boolean?,
	timeLimit: number?,
	onSwingCallback: (() -> ())?,
	onCancelCallback: (() -> ())?
)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	-- Lock movement in place while minigame is active
	DigUIController.LockPlayerMovement()

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

function DigUIController.UnmountMinigame()
	-- Restore player movement when minigame finishes or cancels
	DigUIController.UnlockPlayerMovement()

	if currentHandle then
		Roact.unmount(currentHandle)
		currentHandle = nil
	end
end

return DigUIController
