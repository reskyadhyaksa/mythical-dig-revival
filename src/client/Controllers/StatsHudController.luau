--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local packagesFolder = ReplicatedStorage:WaitForChild("Packages")
local Roact = require(packagesFolder:WaitForChild("Roact"))
local StatsHudGui = require(script.Parent.Parent.Components.StatsHudGui)
local Store = require(script.Parent.Parent.Rodux.Store)

local StatsHudController = {}
local currentHandle: any = nil

function StatsHudController.MountStatsHud(coins: number?, luck: (number | string)?)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local state = Store:getState()

	local element = Roact.createElement(StatsHudGui, {
		Coins = coins or (state and state.Coins) or 0,
		Luck = luck or (state and state.Luck) or "+100%",
	})

	if currentHandle then
		Roact.update(currentHandle, element)
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
