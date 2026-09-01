--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Packages = ReplicatedStorage.Packages
local Roact = require(Packages.Roact)
local DigMinigameHelper = require(script.Parent.Common.DigMinigameHelper)

local DigMinigame = Roact.Component:extend("DigMinigame")

function DigMinigame:init()
	self.startTime = os.clock()
	self.state = {
		timeRemaining = self.props.TimeLimit or 15,
	}

	-- Roact Refs untuk kontrol TweenService & UIGradient
	self.clipFrameRef = Roact.createRef()
	self.shovelRef = Roact.createRef()
	self.timerIconRef = Roact.createRef()
	self.uiGradientRef = Roact.createRef()
	self.tapTextRef = Roact.createRef()
end

function DigMinigame:didMount()
	self.running = true

	-- 1. Countdown Timer Loop
	task.spawn(function()
		while self.running do
			task.wait(0.2)
			if not self.running then
				break
			end

			local elapsed = os.clock() - self.startTime
			local timeLimit = self.props.TimeLimit or 15
			local remaining = math.max(0, math.ceil(timeLimit - elapsed))

			self:setState({
				timeRemaining = remaining,
			})

			if remaining <= 0 then
				if self.props.OnCancel then
					self.props.OnCancel()
				end
				break
			end
		end
	end)

	-- 2. Animasi Getar Jam Alarm Kartun (Cartoon Alarm Clock Ringing Loop)
	task.spawn(function()
		while self.running do
			local timerIcon = self.timerIconRef:getValue()
			if timerIcon then
				local t1 = TweenService:Create(
					timerIcon,
					TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{
						Rotation = -16,
					}
				)
				local t2 = TweenService:Create(
					timerIcon,
					TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{
						Rotation = 16,
					}
				)
				local t3 = TweenService:Create(
					timerIcon,
					TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{
						Rotation = -12,
					}
				)
				local t4 = TweenService:Create(
					timerIcon,
					TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{
						Rotation = 12,
					}
				)
				local t5 = TweenService:Create(
					timerIcon,
					TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{
						Rotation = 0,
					}
				)

				t1:Play()
				t1.Completed:Wait()
				t2:Play()
				t2.Completed:Wait()
				t3:Play()
				t3.Completed:Wait()
				t4:Play()
				t4.Completed:Wait()
				t5:Play()
				t5.Completed:Wait()
			end
			task.wait(0.55)
		end
	end)

	-- 3. Animasi Idle Pulse Lembut Teks "TAP"
	task.spawn(function()
		while self.running do
			local tapText = self.tapTextRef:getValue()
			if tapText then
				local breatheIn = TweenService:Create(
					tapText,
					TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{
						Size = UDim2.fromScale(0.38, 0.80),
					}
				)
				breatheIn:Play()
				breatheIn.Completed:Wait()

				local breatheOut = TweenService:Create(
					tapText,
					TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{
						Size = UDim2.fromScale(0.32, 0.70),
					}
				)
				breatheOut:Play()
				breatheOut.Completed:Wait()
			else
				task.wait(0.2)
			end
		end
	end)
end

function DigMinigame:didUpdate(previousProps)
	local currentHp = self.props.CurrentHp or 100
	local prevHp = previousProps.CurrentHp or 100
	local maxHp = self.props.MaxHp or 100

	local hpRatio = math.clamp(currentHp / maxHp, 0, 1)
	local progress = 1 - hpRatio

	-- 1. Tweening Halus Penambahan Progress Bar (Smooth Bar Action)
	local clipFrame = self.clipFrameRef:getValue()
	if clipFrame then
		local barTween =
			TweenService:Create(clipFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(progress, 0, 1, 0),
			})
		barTween:Play()
	end

	-- Update UIGradient fade dinamis mengikuti progress dan batas hpRatio (0.8 -> 0.5)
	local uiGradient = self.uiGradientRef:getValue()
	if uiGradient then
		uiGradient.Transparency = DigMinigameHelper.GetFadeTransparencySequence(progress, hpRatio)
	end

	-- 2. Animasi Shovel (Getar Kiri-Kanan, Pop-Up Membesar & Efek Impact berbasis Skala)
	local shovel = self.shovelRef:getValue()
	if shovel then
		-- Tween pergeseran posisi X mengikuti ujung bar
		TweenService:Create(shovel, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(progress, 0, 0.5, 0),
		}):Play()

		-- Efek Getar & Impact saat HP berkurang (klik gali)
		if currentHp < prevHp then
			-- Impact Pop Sekop: Membesar seketika dan mengayun ke belakang
			shovel.Size = UDim2.fromScale(0.15, 1.6)
			shovel.Rotation = -32

			-- Getaran Step 1 (Ayun ke Kanan)
			local shake1 =
				TweenService:Create(shovel, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Rotation = 18,
					Size = UDim2.fromScale(0.14, 1.5),
				})
			shake1:Play()

			shake1.Completed:Connect(function()
				-- Getaran Step 2 (Ayun ke Kiri)
				local shake2 =
					TweenService:Create(shovel, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Rotation = -22,
						Size = UDim2.fromScale(0.13, 1.4),
					})
				shake2:Play()

				shake2.Completed:Connect(function()
					-- Kembali ke posisi istirahat normal (Bounce Back)
					TweenService:Create(shovel, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
						Rotation = -10,
						Size = UDim2.fromScale(0.12, 1.35),
					}):Play()
				end)
			end)
		end
	end

	-- 3. Animasi Getar & Impact Teks "TAP" di Tengah Saat Diklik
	local tapText = self.tapTextRef:getValue()
	if tapText and currentHp < prevHp then
		tapText.Size = UDim2.fromScale(0.44, 0.92)
		tapText.Rotation = -8

		local tapShake = TweenService:Create(
			tapText,
			TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Rotation = 6,
				Size = UDim2.fromScale(0.38, 0.82),
			}
		)
		tapShake:Play()

		tapShake.Completed:Connect(function()
			TweenService:Create(
				tapText,
				TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{
					Rotation = 0,
					Size = UDim2.fromScale(0.35, 0.75),
				}
			):Play()
		end)
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

	-- Asset IDs
	local outerContainerAsset = "rbxassetid://77990043906183" -- Container Frame Luar
	local innerProgressBarAsset = "rbxassetid://105807504905048" -- Progress Bar Hijau Dalam
	local countdownAsset = "rbxassetid://126607445864603" -- Countdown Merah Bawah
	local timerIconAsset = "rbxassetid://109376754540674" -- Logo Timer Icon
	local shovelAsset = "rbxassetid://81621266214171" -- Shovel Icon Indicator

	return Roact.createElement("ScreenGui", {
		ResetOnSpawn = false,
		DisplayOrder = 20,
	}, {
		-- Container Utama Minigame (Responsif berbasis Scale untuk semua layar HP / PC)
		MainContainer = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.76),
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
				Image = outerContainerAsset,
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
							Image = innerProgressBarAsset,
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
						Size = UDim2.fromScale(0.12, 1.35),
						Rotation = -10,
						BackgroundTransparency = 1,
						Image = shovelAsset,
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
				Image = countdownAsset,
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
					Image = timerIconAsset,
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
