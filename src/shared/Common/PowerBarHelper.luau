--!strict
local PowerBarHelper = {}

export type LuckTierInfo = {
	Name: string,
	Color: Color3,
	Multiplier: number,
}

-- Menghitung interpolasi warna transisi real-time sesuai persentase progress power
function PowerBarHelper.GetDynamicProgressColor(t: number): Color3
	t = math.clamp(t, 0, 1)
	if t < 0.25 then
		local alpha = t / 0.25
		return Color3.fromHex("E51B24"):Lerp(Color3.fromHex("FF6D00"), alpha)
	elseif t < 0.50 then
		local alpha = (t - 0.25) / 0.25
		return Color3.fromHex("FF6D00"):Lerp(Color3.fromHex("FFEA00"), alpha)
	elseif t < 0.75 then
		local alpha = (t - 0.50) / 0.25
		return Color3.fromHex("FFEA00"):Lerp(Color3.fromHex("68FF00"), alpha)
	else
		local alpha = (t - 0.75) / 0.25
		return Color3.fromHex("68FF00"):Lerp(Color3.fromHex("00FF44"), alpha)
	end
end

-- Menghitung cutoff transparansi gradient agar bar mengisi mulus tanpa merusak sudut rounded
function PowerBarHelper.GetProgressTransparency(progress: number): NumberSequence
	local p = math.clamp(progress, 0, 1)
	if p <= 0.001 then
		return NumberSequence.new(1.0)
	elseif p >= 0.999 then
		return NumberSequence.new(0.0)
	else
		local cutoff = math.clamp(1 - p, 0.002, 0.998)
		return NumberSequence.new({
			NumberSequenceKeypoint.new(0.0, 1.0),
			NumberSequenceKeypoint.new(cutoff - 0.001, 1.0),
			NumberSequenceKeypoint.new(cutoff, 0.0),
			NumberSequenceKeypoint.new(1.0, 0.0),
		})
	end
end

-- Menentukan Nama Tier, Warna UI, dan Nilai Pengali Keberuntungan (Luck Multiplier)
function PowerBarHelper.GetLuckTier(progress: number): LuckTierInfo
	local p = math.clamp(progress, 0, 1)
	if p >= 0.95 then
		return {
			Name = "PERFECT",
			Color = Color3.fromHex("00FF26"),
			Multiplier = 2.5,
		}
	elseif p >= 0.75 then
		return {
			Name = "AMAZING",
			Color = Color3.fromHex("C800DA"),
			Multiplier = 2.0,
		}
	elseif p >= 0.50 then
		return {
			Name = "GREAT",
			Color = Color3.fromHex("00A2FF"),
			Multiplier = 1.5,
		}
	elseif p >= 0.20 then
		return {
			Name = "NICE",
			Color = Color3.fromRGB(255, 255, 255),
			Multiplier = 1.2,
		}
	else
		return {
			Name = "BAD",
			Color = Color3.fromHex("C21B1E"),
			Multiplier = 1.0,
		}
	end
end

return PowerBarHelper
