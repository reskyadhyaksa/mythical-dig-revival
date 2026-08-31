--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.Roact)
local SideMenuGui = require(script.Parent.Parent.Components.SideMenuGui)

local SideMenuController = {}
local currentHandle: any = nil

function SideMenuController.MountSideMenu(onOpenInventory: () -> (), onOpenShop: () -> ())
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local element = Roact.createElement(SideMenuGui, {
		OnOpenInventory = onOpenInventory,
		OnOpenShop = onOpenShop,
	})

	if currentHandle then
		Roact.unmount(currentHandle)
	end

	currentHandle = Roact.mount(element, playerGui, "SideMenuUI")
end

function SideMenuController.UnmountSideMenu()
	if currentHandle then
		Roact.unmount(currentHandle)
		currentHandle = nil
	end
end

return SideMenuController
