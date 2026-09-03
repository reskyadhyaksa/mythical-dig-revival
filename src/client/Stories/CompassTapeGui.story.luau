--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Packages = ReplicatedStorage.Packages
local Roact = require(Packages.Roact)
local CompassTapeGui = require(script.Parent.Parent.Components.CompassTapeGui)

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local dataFolder = sharedFolder:WaitForChild("Data")
local IslandWaypoints = require(dataFolder:WaitForChild("IslandWaypoints")) :: any

local CYCLE_SCALE = 2.0

return function(target: Instance)
	local tapeRef = Roact.createRef()
	local waypointRefs = {}
	for id, _ in IslandWaypoints.GetWaypoints() do
		waypointRefs[id] = Roact.createRef()
	end

	local handle = Roact.mount(
		Roact.createElement(CompassTapeGui, {
			TapeRef = tapeRef,
			WaypointRefs = waypointRefs,
		}),
		target
	)

	local connection = RunService.RenderStepped:Connect(function()
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end

		local tapeFrame = tapeRef and tapeRef:getValue() :: Frame?
		if not tapeFrame then
			return
		end

		local look = camera.CFrame.LookVector
		local yaw = math.deg(math.atan2(look.X, -look.Z))
		if yaw < 0 then
			yaw += 360
		end

		local targetScaleX = 0.5 - (CYCLE_SCALE * (1 + (yaw / 360)))
		tapeFrame.Position = UDim2.new(targetScaleX, 0, 0, 0)

		-- Story preview for waypoint
		for id, wp in IslandWaypoints.GetWaypoints() do
			local wRef = waypointRefs[id]
			local wpGui = wRef and wRef:getValue() :: Frame?
			if wpGui then
				local delta = (315 - yaw + 540) % 360 - 180 -- arah Northwest preview
				local xScale = 0.5 + (delta / 180)
				if xScale >= 0 and xScale <= 1 then
					wpGui.Visible = true
					wpGui.Position = UDim2.new(xScale, 0, 1, 0)
				else
					wpGui.Visible = false
				end
			end
		end
	end)

	return function()
		connection:Disconnect()
		Roact.unmount(handle)
	end
end
