--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local packagesFolder = ReplicatedStorage:WaitForChild("Packages")
local Roact = require(packagesFolder:WaitForChild("Roact"))

local clientFolder = script.Parent.Parent
local componentsFolder = clientFolder:WaitForChild("Components")
local CompassTapeGui = require(componentsFolder:WaitForChild("CompassTapeGui"))

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local dataFolder = sharedFolder:WaitForChild("Data")
local IslandWaypoints = require(dataFolder:WaitForChild("IslandWaypoints")) :: any

local CompassController = {}
local currentHandle: any = nil
local tapeRef: any = nil
local waypointRefs: { [string]: any } = {}
local renderConnection: RBXScriptConnection? = nil

local CYCLE_SCALE = 2.0 -- 1 siklus 360° = 2.0x lebar Viewport tape (Scale-based)

local function IsPlayerInsideIsland(islandId: string, playerPos: Vector3): boolean
	local zonesFolder = workspace:FindFirstChild("Zone") or workspace:FindFirstChild("Zones")
	if not zonesFolder then
		return false
	end

	local islandFolder = zonesFolder:FindFirstChild(islandId)
	if not islandFolder then
		return false
	end

	local borderPart = islandFolder:FindFirstChild("Border", true) :: BasePart?
	if borderPart and borderPart:IsA("BasePart") then
		local relativePos = borderPart.CFrame:PointToObjectSpace(playerPos)
		local halfSize = borderPart.Size / 2
		-- Cek batas horizontal X & Z (dengan toleransi vertikal 500 studs agar lereng/bukit tidak gagal terdeteksi)
		if math.abs(relativePos.X) <= halfSize.X and math.abs(relativePos.Z) <= halfSize.Z then
			if math.abs(relativePos.Y) <= math.max(halfSize.Y, 500) then
				return true
			end
		end
	end

	return false
end

function CompassController.MountCompass()
	if currentHandle then
		return
	end

	local localPlayer = Players.LocalPlayer
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	tapeRef = Roact.createRef()
	waypointRefs = {}

	local waypointsDict = IslandWaypoints.GetWaypoints()
	for islandId, _ in waypointsDict do
		waypointRefs[islandId] = Roact.createRef()
	end

	local element = Roact.createElement(CompassTapeGui, {
		TapeRef = tapeRef,
		WaypointRefs = waypointRefs,
	})

	currentHandle = Roact.mount(element, playerGui, "CompassTapeUI")

	-- Sambungkan ke RenderStepped untuk pergerakan pita & waypoint 60/144+ FPS
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end

	renderConnection = RunService.RenderStepped:Connect(function()
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end

		local localChar = localPlayer.Character
		local hrp = localChar and localChar:FindFirstChild("HumanoidRootPart") :: BasePart?

		local look = camera.CFrame.LookVector
		-- Sumbu Roblox: -Z = Utara (0°), +X = Timur (90°), +Z = Selatan (180°), -X = Barat (270°)
		local cameraYaw = math.deg(math.atan2(look.X, -look.Z))
		if cameraYaw < 0 then
			cameraYaw += 360
		end

		-- 1. Geser pita kompas utama
		local tapeFrame = tapeRef and tapeRef:getValue() :: Frame?
		if tapeFrame then
			local targetScaleX = 0.5 - (CYCLE_SCALE * (1 + (cameraYaw / 360)))
			tapeFrame.Position = UDim2.new(targetScaleX, 0, 0, 0)
		end

		-- 2. Update Waypoint Pulau
		if not hrp then
			-- Jika karakter belum spawn / hilang, sembunyikan semua waypoint
			for _, wRef in waypointRefs do
				local wpGui = wRef and wRef:getValue() :: Frame?
				if wpGui then
					wpGui.Visible = false
				end
			end
			return
		end

		local playerPos = hrp.Position
		for islandId, wpDef in waypointsDict do
			local wRef = waypointRefs[islandId]
			local wpGui = wRef and wRef:getValue() :: Frame?
			if not wpGui then
				continue
			end

			-- Syarat: ketika player berada di dalam region pulau tersebut, waypoint otomatis menghilang
			local isInside = IsPlayerInsideIsland(islandId, playerPos)
			if isInside then
				wpGui.Visible = false
				continue
			end

			-- Hitung bearing sudut dari posisi player ke koordinat target pulau
			local diffX = wpDef.WorldPosition.X - playerPos.X
			local diffZ = wpDef.WorldPosition.Z - playerPos.Z

			-- Jika pemain sudah sampai di titik koordinat (< 25 studs), sembunyikan waypoint
			local distSq = (diffX * diffX) + (diffZ * diffZ)
			if distSq < (25 * 25) then
				wpGui.Visible = false
				continue
			end

			local targetAngle = math.deg(math.atan2(diffX, -diffZ))
			if targetAngle < 0 then
				targetAngle += 360
			end

			-- Selisih sudut pandang kamera (-180° sampai +180°)
			local delta = (targetAngle - cameraYaw + 540) % 360 - 180

			-- Posisi horizontal X di dalam Viewport (0.5 = tepat di tengah bawah pita)
			local xScaleInViewport = 0.5 + (delta / 180)

			-- Tampilkan HANYA jika berada di dalam rentang sudut yang terlihat di kompas
			if xScaleInViewport >= 0 and xScaleInViewport <= 1 then
				wpGui.Visible = true
				wpGui.Position = UDim2.new(xScaleInViewport, 0, 1, 0)
			else
				wpGui.Visible = false
			end
		end
	end)
end

function CompassController.UnmountCompass()
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end

	if currentHandle then
		Roact.unmount(currentHandle)
		currentHandle = nil
	end
	tapeRef = nil
	waypointRefs = {}
end

return CompassController
