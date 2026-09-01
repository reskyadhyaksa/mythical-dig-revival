--!strict
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

return DigMinigameHelper
