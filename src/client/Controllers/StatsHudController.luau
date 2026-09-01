--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)
local StatsHudGui = require(script.Parent.Parent.Components.StatsHudGui)
local Store = require(script.Parent.Parent.Rodux.Store)

local StatsHudController = {}
local currentHandle: any = nil

function StatsHudController.MountStatsHud()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local app = Roact.createElement(RoactRodux.StoreProvider, {
		store = Store,
	}, {
		StatsHud = Roact.createElement(StatsHudGui),
	})

	if currentHandle then
		Roact.update(currentHandle, app)
	else
		currentHandle = Roact.mount(app, playerGui, "StatsHudUI")
	end
end

function StatsHudController.UnmountStatsHud()
	if currentHandle then
		Roact.unmount(currentHandle)
		currentHandle = nil
	end
end

return StatsHudController
