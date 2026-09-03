--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local packagesFolder = ReplicatedStorage:WaitForChild("Packages")
local Roact = require(packagesFolder:WaitForChild("Roact"))

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local dataFolder = sharedFolder:WaitForChild("Data")
local IslandWaypoints = require(dataFolder:WaitForChild("IslandWaypoints")) :: any

local CompassTapeGui = Roact.Component:extend("CompassTapeGui")

export type CardinalMarkerDef = {
	Deg: number,
	Label: string,
	IsMajor: boolean?,
	IsTick: boolean?,
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

function CompassTapeGui:render()
	local tapeRef = self.props.TapeRef
	local waypointRefs = self.props.WaypointRefs or {}

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
					ZIndex = 3,
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
					ZIndex = 3,
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
					Position = UDim2.new(markerScaleInTape, 0, 0.65, 0),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.new(0.045, 0, 0.44, 0),
					BackgroundTransparency = 1,
					Text = item.Label,
					Font = Enum.Font.LuckiestGuy,
					TextScaled = true,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextXAlignment = Enum.TextXAlignment.Center,
					TextYAlignment = Enum.TextYAlignment.Center,
					ZIndex = 3,
				}, {
					UITextSizeConstraint = Roact.createElement("UITextSizeConstraint", {
						MaxTextSize = 15,
						MinTextSize = 9,
					}),
					UIStroke = Roact.createElement("UIStroke", {
						Color = Color3.fromHex("1B5A87"),
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
			Position = UDim2.new(0.5, 0, 1, 0), -- Tepat di batas bawah kontainer
			Size = UDim2.fromOffset(90, 42),
			BackgroundTransparency = 1,
			Visible = false,
			ZIndex = 20, -- ZIndex paling tinggi
		}, {
			-- Segitiga panah ke atas murni berbasis Frame (Warna #1B5A87 + Stroke 1px Putih, setengah badan di dalam dan setengah di luar)
			ArrowContainer = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, -4),
				Size = UDim2.fromOffset(14, 12),
				BackgroundTransparency = 1,
				ClipsDescendants = true,
				BorderSizePixel = 0,
				ZIndex = 21,
			}, {
				TriangleFrame = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.new(0.5, 0, 0, 2),
					Size = UDim2.fromOffset(9, 9),
					BackgroundColor3 = Color3.fromHex("1B5A87"),
					BorderSizePixel = 0,
					Rotation = 45,
					ZIndex = 22,
				}, {
					UIStroke = Roact.createElement("UIStroke", {
						Color = Color3.fromRGB(255, 255, 255),
						Thickness = 1,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}),
				}),
			}),

			-- Nama Pulau (Biru Navy dengan stroke luar putih 2px)
			Label = Roact.createElement("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0.5, 6),
				Size = UDim2.fromOffset(90, 18),
				BackgroundTransparency = 1,
				Text = wp.Name,
				Font = Enum.Font.LuckiestGuy,
				TextSize = 14,
				TextColor3 = Color3.fromHex("00426D"),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Top,
				ZIndex = 21,
			}, {
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromRGB(255, 255, 255),
					Thickness = 2,
				}),
			}),
		})
	end

	return Roact.createElement("ScreenGui", {
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 3,
	}, {
		-- Kontainer Utama Kompas Responsif
		CompassWrapper = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0.02, 0),
			Size = UDim2.new(0.36, 0, 0.054, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, {
			UIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint", {
				AspectRatio = 9.5,
			}),
			UISizeConstraint = Roact.createElement("UISizeConstraint", {
				MinSize = Vector2.new(264, 29),
				MaxSize = Vector2.new(552, 58),
			}),

			-- 1. Kontainer Luar (Stroke Outside #2AACDD ketebalan 2)
			OuterContainer = Roact.createElement("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.fromHex("2772B5"),
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				ZIndex = 1,
			}, {
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(1, 0),
				}),
				OuterStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromHex("2AACDD"),
					Thickness = 2,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}),

				-- 2. Kontainer Dalam (Stroke Inside #1B5A87 ketebalan 1 + Background Gradient)
				InnerContainer = Roact.createElement("Frame", {
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BorderSizePixel = 0,
					ClipsDescendants = true,
					ZIndex = 2,
				}, {
					UICorner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(1, 0),
					}),
					InnerStroke = Roact.createElement("UIStroke", {
						Color = Color3.fromHex("1B5A87"),
						Thickness = 1,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}),
					BackgroundGradient = Roact.createElement("UIGradient", {
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromHex("2772B5")),
							ColorSequenceKeypoint.new(0.5, Color3.fromHex("54A0D0")),
							ColorSequenceKeypoint.new(1.0, Color3.fromHex("2772B5")),
						}),
						Rotation = 0, -- Linear Horizontal
					}),

					-- 3. Viewport Padded untuk Pita Kompas
					TapeViewport = Roact.createElement("Frame", {
						AnchorPoint = Vector2.new(0.5, 0),
						Position = UDim2.new(0.5, 0, 0, 0),
						Size = UDim2.new(0.88, 0, 1, 0),
						BackgroundTransparency = 1,
						ClipsDescendants = true,
						BorderSizePixel = 0,
						ZIndex = 3,
					}, {
						-- Fade halus di ujung batas padding
						UIGradient = Roact.createElement("UIGradient", {
							Transparency = NumberSequence.new({
								NumberSequenceKeypoint.new(0, 1),
								NumberSequenceKeypoint.new(0.08, 0),
								NumberSequenceKeypoint.new(0.92, 0),
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
				}),
			}),

			-- 3. Jarum Penunjuk Atas (Ukuran proporsional tajam: 26x26 px)
			NeedlePointer = Roact.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0, 0),
				Size = UDim2.fromOffset(26, 26),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Image = "rbxassetid://81699964927749",
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 25,
			}),

			-- 4. Viewport Waypoint Pulau (Di bagian bawah kapsul kompas)
			WaypointsViewport = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 0),
				Size = UDim2.new(0.88, 0, 1, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 20,
			}, waypointElements),
		}),
	})
end

return CompassTapeGui
