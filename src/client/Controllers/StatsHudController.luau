--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local packagesFolder = ReplicatedStorage:WaitForChild("Packages")
local Roact = require(packagesFolder:WaitForChild("Roact"))
local clientFolder = script.Parent.Parent
local componentsFolder = clientFolder:WaitForChild("Components")
local roduxFolder = clientFolder:WaitForChild("Rodux")

local StatsHudGui = require(componentsFolder:WaitForChild("StatsHudGui"))
local Store = require(roduxFolder:WaitForChild("Store"))

local StatsHudController = {}
local currentHandle: any = nil

function StatsHudController.MountStatsHud(coins: number?, luck: (number | string)?)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local state = Store:getState()

	local currentCoins = if coins ~= nil then coins else ((state and state.Coins) or 0)
	local currentLuck = if luck ~= nil then luck else ((state and state.Luck) or "+100%")

	local element = Roact.createElement(StatsHudGui, {
		Coins = currentCoins,
		Luck = currentLuck,
	})

	if currentHandle then
		currentHandle = Roact.update(currentHandle, element)
	else
		currentHandle = Roact.mount(element, playerGui, "StatsHudUI")
	end
end

function StatsHudController.UnmountStatsHud()
	if currentHandle then
		Roact.unmount(currentHandle)
		currentHandle = nil
	end
end

return StatsHudController
