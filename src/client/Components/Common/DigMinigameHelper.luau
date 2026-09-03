--!strict
local TweenService = game:GetService("TweenService")

local DigMinigameHelper = {}

-- Helper untuk menghitung Transparency NumberSequence dinamis
-- Bar hijau tetap 100% padat sampai tepat di dekat sekop, lalu memudar lembut di ujung potongan sekop
function DigMinigameHelper.GetFadeTransparencySequence(progress: number, hpRatio: number): NumberSequence
	if progress <= 0.02 then
		return NumberSequence.new(1)
	end

	-- Jarak transisi fade yang pas di ujung potongan bar (tepat di bawah mata sekop)
	local fadeLength = math.min(0.06, progress * 0.3)

	local p1 = math.clamp(progress - fadeLength, 0, 0.995)
	local p2 = math.clamp(progress - (fadeLength * 0.5), p1 + 0.001, 0.997)
	local p3 = math.clamp(progress - (fadeLength * 0.15), p2 + 0.001, 0.999)
	local pEnd = math.clamp(progress, p3 + 0.001, 1.0)

	if pEnd < 1.0 then
		return NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0), -- 100% Opaque (Padat)
			NumberSequenceKeypoint.new(p1, 0), -- 100% Opaque (Tetap padat hingga tepat sebelum sekop)
			NumberSequenceKeypoint.new(p2, 0.25), -- 75% Opaque (Mulai memudar lembut)
			NumberSequenceKeypoint.new(p3, 0.95), -- 5% Opaque
			NumberSequenceKeypoint.new(pEnd, 1.0), -- 0% Opaque (Habis tepat di ujung sekop)
			NumberSequenceKeypoint.new(1.0, 1.0),
		})
	else
		return NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0), -- 100% Opaque (Padat)
			NumberSequenceKeypoint.new(p1, 0), -- 100% Opaque (Tetap padat hingga tepat sebelum sekop)
			NumberSequenceKeypoint.new(p2, 0.25), -- 75% Opaque (Mulai memudar lembut)
			NumberSequenceKeypoint.new(p3, 0.95), -- 5% Opaque
			NumberSequenceKeypoint.new(1.0, 1.0), -- 0% Opaque (Habis tepat di ujung sekop)
		})
	end
end

-- 1. Loop Countdown Timer
function DigMinigameHelper.StartCountdown(
	isRunning: () -> boolean,
	startTime: number,
	timeLimit: number,
	onUpdate: (remaining: number) -> (),
	onCancel: (() -> ())?
)
	task.spawn(function()
		while isRunning() do
			task.wait(0.2)
			if not isRunning() then
				break
			end

			local elapsed = os.clock() - startTime
			local remaining = math.max(0, math.ceil(timeLimit - elapsed))

			onUpdate(remaining)

			if remaining <= 0 then
				if onCancel then
					onCancel()
				end
				break
			end
		end
	end)
end

-- 2. Animasi Getar Jam Alarm Kartun (Cartoon Alarm Clock Ringing Loop)
function DigMinigameHelper.StartAlarmAnimation(
	isRunning: () -> boolean,
	getTimerIcon: () -> ImageLabel?
)
	task.spawn(function()
		while isRunning() do
			local timerIcon = getTimerIcon()
			if timerIcon then
				local t1 = TweenService:Create(
					timerIcon,
					TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Rotation = -16 }
				)
				local t2 = TweenService:Create(
					timerIcon,
					TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Rotation = 16 }
				)
				local t3 = TweenService:Create(
					timerIcon,
					TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Rotation = -12 }
				)
				local t4 = TweenService:Create(
					timerIcon,
					TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Rotation = 12 }
				)
				local t5 = TweenService:Create(
					timerIcon,
					TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{ Rotation = 0 }
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
end

-- 3. Animasi Idle Pulse Lembut Teks "TAP"
function DigMinigameHelper.StartTapPulseAnimation(
	isRunning: () -> boolean,
	getTapText: () -> TextLabel?
)
	task.spawn(function()
		while isRunning() do
			local tapText = getTapText()
			if tapText then
				local breatheIn = TweenService:Create(
					tapText,
					TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{ Size = UDim2.fromScale(0.38, 0.80) }
				)
				breatheIn:Play()
				breatheIn.Completed:Wait()

				local breatheOut = TweenService:Create(
					tapText,
					TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{ Size = UDim2.fromScale(0.32, 0.70) }
				)
				breatheOut:Play()
				breatheOut.Completed:Wait()
			else
				task.wait(0.2)
			end
		end
	end)
end

-- 4. Animasi Pergeseran Progress Bar & Shovel
function DigMinigameHelper.AnimateBarProgress(clipFrame: Frame?, shovel: ImageLabel?, progress: number)
	if clipFrame then
		TweenService:Create(clipFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(progress, 0, 1, 0),
		}):Play()
	end

	if shovel then
		TweenService:Create(shovel, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(progress, 0, 0.5, 0),
		}):Play()
	end
end

-- 5. Animasi Impact / Getar Sekop Saat Diklik
function DigMinigameHelper.AnimateShovelHit(shovel: ImageLabel?)
	if not shovel then return end

	-- Impact Pop Sekop: Membesar seketika dan mengayun ke belakang
	shovel.Size = UDim2.fromScale(1.15, 2.9)
	shovel.Rotation = -32

	-- Getaran Step 1 (Ayun ke Kanan)
	local shake1 = TweenService:Create(shovel, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Rotation = 18,
		Size = UDim2.fromScale(1.1, 2.75),
	})
	shake1:Play()

	shake1.Completed:Connect(function()
		-- Getaran Step 2 (Ayun ke Kiri)
		local shake2 = TweenService:Create(shovel, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Rotation = -22,
			Size = UDim2.fromScale(1.05, 2.6),
		})
		shake2:Play()

		shake2.Completed:Connect(function()
			-- Kembali ke posisi istirahat normal (Bounce Back)
			TweenService:Create(shovel, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Rotation = -10,
				Size = UDim2.fromScale(1, 2.5),
			}):Play()
		end)
	end)
end

-- 6. Animasi Impact / Getar Teks "TAP" Saat Diklik
function DigMinigameHelper.AnimateTapHit(tapText: TextLabel?)
	if not tapText then return end

	tapText.Size = UDim2.fromScale(0.44, 0.92)
	tapText.Rotation = -8

	local tapShake = TweenService:Create(tapText, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Rotation = 6,
		Size = UDim2.fromScale(0.38, 0.82),
	})
	tapShake:Play()

	tapShake.Completed:Connect(function()
		TweenService:Create(tapText, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Rotation = 0,
			Size = UDim2.fromScale(0.35, 0.75),
		}):Play()
	end)
end

return DigMinigameHelper
