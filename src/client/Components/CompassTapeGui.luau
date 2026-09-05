--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local packagesFolder = ReplicatedStorage:WaitForChild("Packages")
local Roact = require(packagesFolder:WaitForChild("Roact"))

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local dataFolder = sharedFolder:WaitForChild("Data")
local IslandWaypoints = require(dataFolder:WaitForChild("IslandWaypoints")) :: any
local DeviceHelper = require(sharedFolder:WaitForChild("Common"):WaitForChild("DeviceHelper"))

local Common = script.Parent.Common
local CompassBarButton = require(Common.CompassBarButton)

local CompassTapeGui = Roact.Component:extend("CompassTapeGui")

export type CardinalMarkerDef = {
	Deg: number,
	Label: string,
	IsMajor: boolean?,
	IsTick: boolean?,
}

export type BarButtonDef = {
	Id: string,
	Label: string,
	Icon: string,
	OnActivated: (() -> ())?,
}

local CARDINALS: { CardinalMarkerDef } = {
	{ Deg = 0, Label = "N", IsMajor = true },
	{ Deg = 15, Label = "", IsTick = true },
	{ Deg = 30, Label = "", IsTick = true },
	{ Deg = 45, Label = "NE", IsMajor = true },
	{ Deg = 60, Label = "", IsTick = true },
	{ Deg = 75, Label = "", IsTick = true },
	{ Deg = 90, Label = "E", IsMajor = true },
	{ Deg = 105, Label = "", IsTick = true },
	{ Deg = 120, Label = "", IsTick = true },
	{ Deg = 135, Label = "SE", IsMajor = true },
	{ Deg = 150, Label = "", IsTick = true },
	{ Deg = 165, Label = "", IsTick = true },
	{ Deg = 180, Label = "S", IsMajor = true },
	{ Deg = 195, Label = "", IsTick = true },
	{ Deg = 210, Label = "", IsTick = true },
	{ Deg = 225, Label = "SW", IsMajor = true },
	{ Deg = 240, Label = "", IsTick = true },
	{ Deg = 255, Label = "", IsTick = true },
	{ Deg = 270, Label = "W", IsMajor = true },
	{ Deg = 285, Label = "", IsTick = true },
	{ Deg = 300, Label = "", IsTick = true },
	{ Deg = 315, Label = "NW", IsMajor = true },
	{ Deg = 330, Label = "", IsTick = true },
	{ Deg = 345, Label = "", IsTick = true },
}

local TOTAL_CYCLES = 3 -- 3 siklus untuk perulangan mulus tanpa batas
local CYCLE_SCALE = 2.0 -- 1 siklus 360° = 2.0x lebar Viewport tape

local DEFAULT_LEFT_BUTTONS: { BarButtonDef } = {
	{ Id = "Home", Label = "Home", Icon = "rbxassetid://120414131422133" },
	{ Id = "Quest", Label = "Quest", Icon = "rbxassetid://140095631863306" },
}

local DEFAULT_RIGHT_BUTTONS: { BarButtonDef } = {
	{ Id = "Index", Label = "Index", Icon = "rbxassetid://97029252899728" },
	{ Id = "Settings", Label = "Options", Icon = "rbxassetid://89287268052902" },
}

function CompassTapeGui:render()
	local tapeRef = self.props.TapeRef
	local waypointRefs = self.props.WaypointRefs or {}
	local leftButtons = self.props.LeftButtons or DEFAULT_LEFT_BUTTONS
	local rightButtons = self.props.RightButtons or DEFAULT_RIGHT_BUTTONS

	local deviceType = DeviceHelper.GetDeviceType()
	local isMobile = deviceType == "Mobile"

	-- Buat elemen-elemen marker berbasis SCALE penuh untuk responsivitas multi-device
	local markers = {}
	for cycle = 0, TOTAL_CYCLES - 1 do
		local cycleBaseScale = cycle / TOTAL_CYCLES

		for idx, item in ipairs(CARDINALS) do
			local markerScaleInTape = cycleBaseScale + ((item.Deg / 360) / TOTAL_CYCLES)

			if item.IsTick then
				-- Garis Penanda Derajat Minor (Scale)
				markers[string.format("Tick_%d_%d", cycle, idx)] = Roact.createElement("Frame", {
					Position = UDim2.new(markerScaleInTape, 0, 0.18, 0),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.new(0.003, 0, 0.18, 0),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.1,
					BorderSizePixel = 0,
					ZIndex = 4,
				}, {
					UICorner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(1, 0),
					}),
					UIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint", {
						AspectRatio = 0.35,
					}),
				})
			else
				-- Garis Penanda Derajat Major (Tebal Putih di Atas)
				markers[string.format("MajorTick_%d_%d", cycle, idx)] = Roact.createElement("Frame", {
					Position = UDim2.new(markerScaleInTape, 0, 0.20, 0),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.new(0.005, 0, 0.24, 0),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BorderSizePixel = 0,
					ZIndex = 4,
				}, {
					UICorner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, 1),
					}),
					UIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint", {
						AspectRatio = 0.45,
					}),
				})

				-- Teks Huruf Arah Mata Angin (Putih dengan Stroke Biru Tua di Bawah)
				markers[string.format("Label_%d_%d", cycle, idx)] = Roact.createElement("TextLabel", {
					Position = UDim2.new(markerScaleInTape, 0, if isMobile then 0.7 else 0.65, 0),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.new(if isMobile then 0.025 else 0.045, 0, if isMobile then 0.1 else 0.44, 0),
					BackgroundTransparency = 1,
					Text = item.Label,
					Font = Enum.Font.LuckiestGuy,
					TextScaled = true,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextXAlignment = Enum.TextXAlignment.Center,
					TextYAlignment = Enum.TextYAlignment.Center,
					ZIndex = 4,
				}, {
					UITextSizeConstraint = Roact.createElement("UITextSizeConstraint", {
						MaxTextSize = if isMobile then 13 else 15,
						MinTextSize = 8,
					}),
					UIStroke = Roact.createElement("UIStroke", {
						Color = Color3.fromHex("003c66"),
						Thickness = 1.4,
					}),
				})
			end
		end
	end

	-- Buat elemen-elemen Waypoint Pulau terdaftar
	local waypointElements = {}
	local waypointsDict = IslandWaypoints.GetWaypoints()
	for islandId, wp in waypointsDict do
		waypointElements["Waypoint_" .. islandId] = Roact.createElement("Frame", {
			[Roact.Ref] = waypointRefs[islandId],
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 1, 0),
			Size = UDim2.fromScale(0.45, 0.95),
			BackgroundTransparency = 1,
			Visible = false,
			ZIndex = 20,
		}, {
			-- Segitiga panah ke atas murni berbasis Frame
			ArrowContainer = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.35),
				Size = UDim2.fromScale(0.16, 0.24),
				BackgroundTransparency = 1,
				ClipsDescendants = true,
				BorderSizePixel = 0,
				ZIndex = 21,
			}, {
				TriangleFrame = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.fromScale(0.5, 0.12),
					Size = UDim2.fromScale(0.75, 0.75),
					BackgroundColor3 = Color3.fromHex("1B5A87"),
					BorderSizePixel = 0,
					Rotation = 45,
					ZIndex = 22,
				}, {
					UIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint", {
						AspectRatio = 1.0,
					}),
					UIStroke = Roact.createElement("UIStroke", {
						Color = Color3.fromRGB(255, 255, 255),
						Thickness = 1,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}),
				}),
			}),

			-- Nama Pulau
			Label = Roact.createElement("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.56),
				Size = UDim2.fromScale(1.2, 0.44),
				BackgroundTransparency = 1,
				Text = wp.Name,
				Font = Enum.Font.LuckiestGuy,
				TextScaled = true,
				TextColor3 = Color3.fromHex("00426D"),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Top,
				ZIndex = 21,
			}, {
				UITextSizeConstraint = Roact.createElement("UITextSizeConstraint", {
					MaxTextSize = if isMobile then 9 else 14,
					MinTextSize = 8,
				}),
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromRGB(255, 255, 255),
					Thickness = if isMobile then 1.5 else 2.0,
				}),
			}),
		})
	end

	-- Render Tombol Kiri (Home, Quest, dll.)
	local leftButtonElements = {
		UIListLayout = Roact.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(if isMobile then 0.1 else 0.025, 0),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			FillDirection = Enum.FillDirection.Horizontal,
		}),
	}
	for i, btn in ipairs(leftButtons) do
		leftButtonElements["LeftBtn_" .. btn.Id] = Roact.createElement(CompassBarButton, {
			Id = btn.Id,
			Label = btn.Label,
			Icon = btn.Icon,
			LayoutOrder = i,
			DeviceType = deviceType,
			OnActivated = btn.OnActivated,
		})
	end

	-- Render Tombol Kanan (Index, Options/Settings, dll.)
	local rightButtonElements = {
		UIListLayout = Roact.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(if isMobile then 0.2 else 0.025, 0),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			FillDirection = Enum.FillDirection.Horizontal,
		}),
	}
	for i, btn in ipairs(rightButtons) do
		rightButtonElements["RightBtn_" .. btn.Id] = Roact.createElement(CompassBarButton, {
			Id = btn.Id,
			Label = btn.Label,
			Icon = btn.Icon,
			LayoutOrder = i,
			DeviceType = deviceType,
			OnActivated = btn.OnActivated,
		})
	end

	local containerWidthScale = if isMobile then 0.4 else 0.52
	local containerHeightScale = if isMobile then 0.088 else 0.062

	return Roact.createElement("ScreenGui", {
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 3,
	}, {
		-- Kontainer Luar Kapsul Pembungkus Seluruh Kompas & Tombol
		OuterCompassCapsule = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0.015, 0),
			Size = UDim2.new(containerWidthScale, 0, containerHeightScale, 0),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			ZIndex = 1,
		}, {
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
			-- Outline Biru Tua Tebal
			OuterStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromHex("073f5b"),
				Thickness = if isMobile then 2.0 else 3.0,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			-- Linear Gradient dari Atas (#00a9f1) ke Bawah (#036291)
			CapsuleGradient = Roact.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0.0, Color3.fromHex("00a9f1")), -- Cyan/Bright Blue Top
					ColorSequenceKeypoint.new(1.0, Color3.fromHex("036291")), -- Rich Deep Blue Bottom
				}),
				Rotation = 90, -- Top to Bottom
			}),
			UISizeConstraint = Roact.createElement("UISizeConstraint", {
				MinSize = if isMobile then Vector2.new(320, 36) else Vector2.new(460, 42),
				MaxSize = if isMobile then Vector2.new(580, 52) else Vector2.new(740, 62),
			}),

			-- 1. Sisi Kiri: Daftar Tombol Kiri (Home, Quest)
			LeftButtonGroup = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(if isMobile then 0.045 else 0.015, 0, 0.5, 0),
				Size = UDim2.new(0.18, 0, 0.88, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 3,
			}, leftButtonElements),

			-- 2. Sisi Tengah: Kontainer Pita Kompas (Warna Biru Lebih Gelap)
			CompassCenterFrame = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(if isMobile then 0.5 else 0.6, 0, 0.76, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BorderSizePixel = 0,
				ZIndex = 2,
			}, {
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(1, 0),
				}),
				InnerStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromHex("0a4773"),
					Thickness = 1.5,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}),
				InnerGradient = Roact.createElement("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0.0, Color3.fromHex("166ca3")),
						ColorSequenceKeypoint.new(1.0, Color3.fromHex("0e4b77")),
					}),
					Rotation = 90,
				}),

				-- Viewport Padded untuk Pita Kompas
				TapeViewport = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.new(0.5, 0, 0, 0),
					Size = UDim2.new(if isMobile then 0.8 else 0.92, 0, 1, 0),
					BackgroundTransparency = 1,
					ClipsDescendants = true,
					BorderSizePixel = 0,
					ZIndex = 3,
				}, {
					-- Fade halus di ujung batas padding
					UIGradient = Roact.createElement("UIGradient", {
						Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 1),
							NumberSequenceKeypoint.new(0.06, 0),
							NumberSequenceKeypoint.new(0.94, 0),
							NumberSequenceKeypoint.new(1, 1),
						}),
					}),

					-- Pita Dalam berbasis SCALE yang bergerak bergulir sesuai sudut kamera
					TapeInner = Roact.createElement("Frame", {
						[Roact.Ref] = tapeRef,
						Position = UDim2.new(0.5 - CYCLE_SCALE, 0, 0, 0),
						Size = UDim2.new(CYCLE_SCALE * TOTAL_CYCLES, 0, 1, 0),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						ZIndex = 3,
					}, markers),
				}),

				-- Jarum Penunjuk Atas
				NeedlePointer = Roact.createElement("ImageLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0, 0),
					Size = if isMobile then UDim2.fromOffset(18, 18) else UDim2.fromOffset(26, 26),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Image = "rbxassetid://81699964927749",
					ScaleType = Enum.ScaleType.Fit,
					ZIndex = 25,
				}),
			}),

			-- 3. Sisi Kanan: Daftar Tombol Kanan (Index, Options/Settings)
			RightButtonGroup = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				-- Position = UDim2.new(0.985, 0, 0.5, 0),
				Position = UDim2.new(if isMobile then 0.95 else 0.985, 0, 0.5, 0),
				Size = UDim2.new(0.18, 0, 0.88, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 3,
			}, rightButtonElements),

			-- 4. Viewport Waypoint Pulau (Di bagian bawah kapsul kompas)
			WaypointsViewport = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 0),
				Size = UDim2.new(if isMobile then 0.40 else 0.60, 0, 1, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 20,
			}, waypointElements),
		}),
	})
end

return CompassTapeGui
