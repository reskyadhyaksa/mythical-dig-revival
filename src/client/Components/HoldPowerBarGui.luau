--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local packagesFolder = ReplicatedStorage:WaitForChild("Packages")
local Roact = require(packagesFolder:WaitForChild("Roact"))

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local commonFolder = sharedFolder:WaitForChild("Common")
local PowerBarHelper = require(commonFolder:WaitForChild("PowerBarHelper")) :: any
local DeviceHelper = require(ReplicatedStorage.Shared.Common.DeviceHelper)

local HoldPowerBarGui = Roact.Component:extend("HoldPowerBarGui")
local deviceType = DeviceHelper.GetDeviceType()

function HoldPowerBarGui:render()
	local visible = self.props.Visible or false
	local progress = math.clamp(self.props.Progress or 0, 0, 1)
	local multiplier = self.props.Multiplier or 1.0

	local currentColor = PowerBarHelper.GetDynamicProgressColor(progress)
	local transparencySeq = PowerBarHelper.GetProgressTransparency(progress)

	return Roact.createElement("ScreenGui", {
		ResetOnSpawn = false,
		DisplayOrder = 15,
		Enabled = visible,
	}, {
		-- Kontainer Utama di Samping Kanan Karakter (Berbasis Scale & AspectRatio)
		PowerBarWrapper = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.64, 0.44),
			-- Size = UDim2.fromScale(0.06, 0.28),
			Size = if deviceType == "Mobile" then UDim2.fromScale(0.1, 0.32) else UDim2.fromScale(0.06, 0.28),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, {
			UIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint", {
				AspectRatio = 0.364, -- 80 / 220
				DominantAxis = Enum.DominantAxis.Height,
			}),

			-- 1. Teks Pengali Luck di Atas Kapsul (Mengikuti Warna Power Aktif Secara Real-Time)
			MultiplierLabel = Roact.createElement("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 0.08),
				Size = UDim2.fromScale(1.0, 0.12),
				BackgroundTransparency = 1,
				Text = string.format("%.1fX", multiplier),
				Font = Enum.Font.LuckiestGuy,
				TextScaled = true,
				TextColor3 = currentColor,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Bottom,
				ZIndex = 5,
			}, {
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromRGB(0, 0, 0),
					Thickness = 2,
				}),
			}),

			-- 2. Teks "LUCK BOOST" Vertikal di Sisi Kiri Bar
			LuckBoostLabel = Roact.createElement("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				-- Position = UDim2.fromScale(0.18, 0.67),
				Position = if deviceType == "Mobile" then UDim2.fromScale(0.1, 0.69) else UDim2.fromScale(0.18, 0.67),
				-- Size = UDim2.fromScale(2.0, 0.09),
				Size = if deviceType == "Mobile" then UDim2.fromScale(2.0, 0.1) else UDim2.fromScale(2.0, 0.09),
				Rotation = -90,
				BackgroundTransparency = 1,
				Text = "LUCK BOOST",
				Font = Enum.Font.LuckiestGuy,
				TextScaled = true,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				ZIndex = 5,
			}, {
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromRGB(0, 0, 0),
					Thickness = 1.5,
				}),
			}),

			-- 3. Kapsul Kontainer Bar Power (Full Rounded + Stroke Outside Putih)
			CapsuleContainer = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.55),
				Size = UDim2.fromScale(0.35, 0.82),
				BackgroundColor3 = Color3.fromRGB(20, 25, 35),
				BackgroundTransparency = 0.5,
				BorderSizePixel = 0,
				ClipsDescendants = true,
				ZIndex = 2,
			}, {
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(1, 0),
				}),
				CapsuleStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromRGB(255, 255, 255),
					Thickness = 2.5,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}),

				-- 4. Fill Bar Statis Berisi Gradient Penuh & Sempurna (100% Rounded di setiap sudut)
				FillBar = Roact.createElement("Frame", {
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BorderSizePixel = 0,
					ZIndex = 3,
				}, {
					UICorner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(1, 0),
					}),

					-- Gradient Warna Harmonis & Cerah (Merah -> Oranye -> Kuning -> Lime -> Hijau Neon)
					ColorGradient = Roact.createElement("UIGradient", {
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0.0, Color3.fromHex("00FF44")), -- Atas: Perfect (Emerald Neon Green)
							ColorSequenceKeypoint.new(0.25, Color3.fromHex("68FF00")), -- 75%: Amazing (Vibrant Lime)
							ColorSequenceKeypoint.new(0.50, Color3.fromHex("FFEA00")), -- 50%: Great (Golden Yellow)
							ColorSequenceKeypoint.new(0.75, Color3.fromHex("FF6D00")), -- 25%: Nice (Amber Orange)
							ColorSequenceKeypoint.new(1.0, Color3.fromHex("E51B24")), -- Bawah: Bad (Deep Red)
						}),
						Rotation = 90, -- Atas ke Bawah
						Transparency = transparencySeq, -- Memotong progress secara presisi dari bawah ke atas
					}),
				}),
			}),
		}),
	})
end

return HoldPowerBarGui
