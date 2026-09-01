--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.Roact)
local RightMenuGui = require(script.Parent.Parent.Components.RightMenuGui)

local RightMenuController = {}
local currentHandle: any = nil

function RightMenuController.MountRightMenu(onOpenInventory: () -> (), onOpenShop: () -> ())
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local element = Roact.createElement(RightMenuGui, {
		OnOpenInventory = onOpenInventory,
		OnOpenShop = onOpenShop,
	})

	if currentHandle then
		Roact.unmount(currentHandle)
	end

	currentHandle = Roact.mount(element, playerGui, "RightMenuUI")
end

function RightMenuController.UnmountRightMenu()
	if currentHandle then
		Roact.unmount(currentHandle)
		currentHandle = nil
	end
end

return RightMenuController
