--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Roact = require(Packages:WaitForChild("Roact"))

local clientFolder = script.Parent.Parent
local componentsFolder = clientFolder:WaitForChild("Components")
local Controllers = clientFolder:WaitForChild("Controllers")

local MobileDigButtonGui = require(componentsFolder:WaitForChild("MobileDigButtonGui"))
local DeviceHelper = require(ReplicatedStorage.Shared.Common.DeviceHelper)

local MobileDigController = {}
local currentHandle: any = nil

local function IsTouchDevice(): boolean
	local deviceType = DeviceHelper.GetDeviceType()
	return UserInputService.TouchEnabled or deviceType == "Mobile" or deviceType == "Tablet"
end

function MobileDigController.Mount()
	if not IsTouchDevice() then
		return
	end

	local localPlayer = Players.LocalPlayer
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local DigController = require(Controllers:WaitForChild("DigController")) :: any
	local HoldPowerController = require(Controllers:WaitForChild("HoldPowerController")) :: any
	local AutoDigController = require(Controllers:WaitForChild("AutoDigController")) :: any
	local ToolController = require(Controllers:WaitForChild("ToolController")) :: any

	local function HandlePress()
		if DigController.IsMinigameActive() then
			local swingAction = DigController.GetSwingAction()
			if swingAction then
				swingAction()
			end
			return
		end

		if AutoDigController.IsActive() then
			return
		end

		if not ToolController.IsHoldingShovel() then
			ToolController.ToggleShovel()
		end

		HoldPowerController.StartHold(function(multiplier)
			DigController.StartDig(multiplier)
		end)
	end

	local function HandleRelease()
		if HoldPowerController.IsHolding() then
			HoldPowerController.ReleaseHold()
		end
	end

	local element = Roact.createElement(MobileDigButtonGui, {
		Visible = true,
		OnPress = HandlePress,
		OnRelease = HandleRelease,
		IsMinigameActive = DigController.IsMinigameActive(),
	})

	if currentHandle then
		currentHandle = Roact.update(currentHandle, element)
	else
		currentHandle = Roact.mount(element, playerGui, "MobileDigButtonUI")
	end
end

function MobileDigController.Update()
	if not currentHandle then
		MobileDigController.Mount()
		return
	end

	local DigController = require(Controllers:WaitForChild("DigController")) :: any
	local HoldPowerController = require(Controllers:WaitForChild("HoldPowerController")) :: any
	local AutoDigController = require(Controllers:WaitForChild("AutoDigController")) :: any
	local ToolController = require(Controllers:WaitForChild("ToolController")) :: any

	local function HandlePress()
		if DigController.IsMinigameActive() then
			local swingAction = DigController.GetSwingAction()
			if swingAction then
				swingAction()
			end
			return
		end

		if AutoDigController.IsActive() then
			return
		end

		if not ToolController.IsHoldingShovel() then
			ToolController.ToggleShovel()
		end

		HoldPowerController.StartHold(function(multiplier)
			DigController.StartDig(multiplier)
		end)
	end

	local function HandleRelease()
		if HoldPowerController.IsHolding() then
			HoldPowerController.ReleaseHold()
		end
	end

	local element = Roact.createElement(MobileDigButtonGui, {
		Visible = true,
		OnPress = HandlePress,
		OnRelease = HandleRelease,
		IsMinigameActive = DigController.IsMinigameActive(),
	})

	currentHandle = Roact.update(currentHandle, element)
end

return MobileDigController
