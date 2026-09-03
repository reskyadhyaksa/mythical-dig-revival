--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local packagesFolder = ReplicatedStorage:WaitForChild("Packages")
local DeviceHelper = require(ReplicatedStorage.Shared.Common.DeviceHelper)
local Roact = require(packagesFolder:WaitForChild("Roact"))
local DigMinigameHelper = require(script.Parent.Common.DigMinigameHelper)

local ASSETS = {
	OuterContainer = "rbxassetid://77990043906183",
	InnerProgressBar = "rbxassetid://105807504905048",
	Countdown = "rbxassetid://126607445864603",
	TimerIcon = "rbxassetid://109376754540674",
	Shovel = "rbxassetid://83791111239909",
}

local DigMinigame = Roact.Component:extend("DigMinigame")
local deviceType = DeviceHelper.GetDeviceType()

function DigMinigame:init()
	self.startTime = os.clock()
	self.state = {
		timeRemaining = self.props.TimeLimit or 15,
	}

	-- Roact Refs untuk kontrol animasi UI
	self.clipFrameRef = Roact.createRef()
	self.shovelRef = Roact.createRef()
	self.timerIconRef = Roact.createRef()
	self.uiGradientRef = Roact.createRef()
	self.tapTextRef = Roact.createRef()
end

function DigMinigame:didMount()
	self.running = true

	-- 1. Countdown Timer Loop
	DigMinigameHelper.StartCountdown(
		function()
			return self.running
		end,
		self.startTime,
		self.props.TimeLimit or 15,
		function(remaining)
			self:setState({ timeRemaining = remaining })
		end,
		self.props.OnCancel
	)

	-- 2. Animasi Getar Jam Alarm Kartun
	DigMinigameHelper.StartAlarmAnimation(function()
		return self.running
	end, function()
		return self.timerIconRef:getValue()
	end)

	-- 3. Animasi Idle Pulse Lembut Teks "TAP"
	DigMinigameHelper.StartTapPulseAnimation(function()
		return self.running
	end, function()
		return self.tapTextRef:getValue()
	end)
end

function DigMinigame:didUpdate(previousProps)
	local currentHp = self.props.CurrentHp or 100
	local prevHp = previousProps.CurrentHp or 100
	local maxHp = self.props.MaxHp or 100

	local hpRatio = math.clamp(currentHp / maxHp, 0, 1)
	local progress = 1 - hpRatio

	local clipFrame = self.clipFrameRef:getValue()
	local shovel = self.shovelRef:getValue()
	local uiGradient = self.uiGradientRef:getValue()
	local tapText = self.tapTextRef:getValue()

	-- 1. Tweening Progress Bar & Posisi Sekop
	DigMinigameHelper.AnimateBarProgress(clipFrame, shovel, progress)

	-- 2. Update UIGradient fade dinamis
	if uiGradient then
		uiGradient.Transparency = DigMinigameHelper.GetFadeTransparencySequence(progress, hpRatio)
	end

	-- 3. Animasi Impact saat HP berkurang (klik gali)
	if currentHp < prevHp then
		DigMinigameHelper.AnimateShovelHit(shovel)
		DigMinigameHelper.AnimateTapHit(tapText)
	end
end

function DigMinigame:willUnmount()
	self.running = false
end

function DigMinigame:render()
	local currentHp = self.props.CurrentHp or 100
	local maxHp = self.props.MaxHp or 100
	local isTooWeak = self.props.IsTooWeak or false
	local onSwing = self.props.OnSwing
	local timeRemaining = self.state.timeRemaining

	local hpRatio = math.clamp(currentHp / maxHp, 0, 1)
	local progress = 1 - hpRatio

	return Roact.createElement("ScreenGui", {
		ResetOnSpawn = false,
		DisplayOrder = 20,
	}, {
		-- Container Utama Minigame (Responsif berbasis Scale untuk semua layar HP / PC)
		MainContainer = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			-- Position = UDim2.fromScale(0.5, 0.67),
			Position = if deviceType == "Mobile" then UDim2.fromScale(0.5, 0.625) else UDim2.fromScale(0.5, 0.7),
			Size = UDim2.fromScale(0.65, 0.088),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, {
			-- Constraint Rasio Aspek agar bentuk bar selalu proporsional dan tidak gepeng di HP
			UIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint", {
				AspectRatio = 7.05,
				DominantAxis = Enum.DominantAxis.Width,
			}),

			-- Batasan Ukuran Minimum (Layar HP Kecil) & Maksimum (Monitor Desktop)
			UISizeConstraint = Roact.createElement("UISizeConstraint", {
				MinSize = Vector2.new(280, 40),
				MaxSize = Vector2.new(540, 76),
			}),

			-- 1. Bagian Luar: Container Progress Bar
			OuterContainer = Roact.createElement("ImageButton", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Image = ASSETS.OuterContainer,
				ScaleType = Enum.ScaleType.Stretch,
				AutoButtonColor = false,

				[Roact.Event.Activated] = function()
					if not isTooWeak and onSwing then
						onSwing()
					end
				end,
			}, {
				-- Area Slot Dalam (Menggunakan Scale Responsif murni)
				InnerSlotFrame = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(0.938, 0.59),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
				}, {
					-- Frame Pemotong (Clip Frame) yang dipotong dinamis & di-tween sesuai progress
					ClipFrame = Roact.createElement("Frame", {
						[Roact.Ref] = self.clipFrameRef,
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.fromScale(0, 0.5),
						Size = UDim2.new(progress, 0, 1, 0),
						ClipsDescendants = true,
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						ZIndex = 2,
					}, {
						-- 2. Bagian Dalam: Gambar Bar Hijau Glossy Berukuran Penuh dengan UIGradient Dinamis
						InnerBarImage = Roact.createElement("ImageLabel", {
							AnchorPoint = Vector2.new(0, 0.5),
							Position = UDim2.fromScale(0, 0.5),
							Size = UDim2.new(1 / math.max(progress, 0.0001), 0, 1, 0),
							BackgroundTransparency = 1,
							Image = ASSETS.InnerProgressBar,
							ScaleType = Enum.ScaleType.Stretch,
							ZIndex = 2,
						}, {
							-- UIGradient diletakkan langsung di dalam ImageLabel dengan keypoint dinamis yang selalu memudar di ujung potongan
							UIGradient = Roact.createElement("UIGradient", {
								[Roact.Ref] = self.uiGradientRef,
								Rotation = 0,
								Transparency = DigMinigameHelper.GetFadeTransparencySequence(progress, hpRatio),
							}),
						}),
					}),

					-- Teks "TAP" di Tengah Inner Progress Bar (ZIndex 4: Di Atas Bar Hijau, Di Bawah Sekop ZIndex 5)
					TapText = Roact.createElement("TextLabel", {
						[Roact.Ref] = self.tapTextRef,
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(0.35, 0.75),
						BackgroundTransparency = 1,
						Text = "TAP",
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextScaled = true,
						Font = Enum.Font.LuckiestGuy,
						TextXAlignment = Enum.TextXAlignment.Center,
						TextYAlignment = Enum.TextYAlignment.Center,
						ZIndex = 4,
					}, {
						UIStroke = Roact.createElement("UIStroke", {
							Color = Color3.fromRGB(0, 0, 0),
							Thickness = 2.0,
						}),
						UIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint", {
							AspectRatio = 2.5,
						}),
					}),

					-- 4. Shovel Marker Indicator (Bergerak, membesar & bergetar dengan TweenService berbasis Skala)
					ShovelMarker = Roact.createElement("ImageLabel", {
						[Roact.Ref] = self.shovelRef,
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.new(progress, 0, 0.5, 0),
						Size = UDim2.fromScale(1, 2.5),
						Rotation = -10,
						BackgroundTransparency = 1,
						Image = ASSETS.Shovel,
						ZIndex = 5,
					}, {
						UIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint", {
							AspectRatio = 1.0,
						}),
					}),
				}),
			}),

			-- 3. Bagian Countdown Merah (Anchor Point di x: 0, y: 1 di bawah container luar berbasis Skala)
			CountdownContainer = Roact.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromScale(0, 1.575),
				Size = UDim2.fromScale(0.32, 0.58),
				BackgroundTransparency = 1,
				Image = ASSETS.Countdown,
				ScaleType = Enum.ScaleType.Fit,
			}, {
				UIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint", {
					AspectRatio = 3.8,
					DominantAxis = Enum.DominantAxis.Height,
				}),

				-- Logo Timer Icon
				TimerIcon = Roact.createElement("ImageLabel", {
					[Roact.Ref] = self.timerIconRef,
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.fromScale(-0.12, 0.4),
					Size = UDim2.fromScale(1, 1.55),
					BackgroundTransparency = 1,
					Image = ASSETS.TimerIcon,
					ZIndex = 3,
				}, {
					UIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint", {
						AspectRatio = 1.0,
					}),
				}),

				-- Teks Waktu (Menggunakan Font Global LuckiestGuy dan TextScaled = true)
				TimeText = Roact.createElement("TextLabel", {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.fromScale(0.3, 0.5),
					Size = UDim2.fromScale(0.7, 0.5),
					BackgroundTransparency = 1,
					Text = string.format("Time : %ds", timeRemaining),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextScaled = true,
					Font = Enum.Font.LuckiestGuy,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Center,
					ZIndex = 2,
				}, {
					UIStroke = Roact.createElement("UIStroke", {
						Color = Color3.fromRGB(0, 0, 0),
						Thickness = 1.5,
					}),
				}),
			}),
		}),
	})
end

return DigMinigame
