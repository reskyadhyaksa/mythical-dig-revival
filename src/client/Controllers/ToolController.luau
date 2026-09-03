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

function ToolController.GetCurrentEquippedTool(): Tool?
	local char = Players.LocalPlayer.Character
	return char and char:FindFirstChildOfClass("Tool")
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
	local equippedTool = char:FindFirstChildOfClass("Tool")
	local isHoldingShovel = equippedTool and (equippedTool.Name:find("Shovel") ~= nil or equippedTool.Name:find("Sekop") ~= nil)

	if isHoldingShovel and humanoid then
		humanoid:UnequipTools()
		HotbarController.SetState(false, nil, nil, "", "")
	else
		if equippedTool and humanoid then
			humanoid:UnequipTools()
		end

		local backpack = localPlayer:FindFirstChildOfClass("Backpack")
		if backpack then
			for _, tool in backpack:GetChildren() do
				if not tool.Name:find("Shovel") and not tool.Name:find("Sekop") then
					tool:Destroy()
				end
			end
		end

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

		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if ToolController.IsHoldingShovel() then
				HoldPowerController.StartHold(function(multiplier)
					DigController.StartDig(multiplier)
				end)
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if HoldPowerController.IsHolding() then
				HoldPowerController.ReleaseHold()
			end
		end
	end)
end

return ToolController
