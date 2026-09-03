--!strict
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local DeviceHelper = {}

-- Mengecek apakah perangkat adalah Console (PlayStation / Xbox)
function DeviceHelper.IsConsole(): boolean
	return GuiService:IsTenFootInterface()
end

-- Mengecek apakah perangkat adalah Mobile / Tablet / PC
function DeviceHelper.IsMobile(): boolean
	-- Termasuk Mobile, Tablet, dan PC (semua perangkat non-console)
	return not DeviceHelper.IsConsole()
end

-- Mendapatkan tipe perangkat secara spesifik: "Mobile" | "Tablet" | "Console" | "PC"
function DeviceHelper.GetDeviceType(): "Mobile" | "Tablet" | "Console" | "PC"
	if DeviceHelper.IsConsole() then
		return "Console"
	end

	local isTouch = if RunService:IsStudio()
		then UserInputService.TouchEnabled
		else (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)

	if isTouch then
		local camera = workspace.CurrentCamera
		local viewport = if camera then camera.ViewportSize else Vector2.new(1920, 1080)
		-- Layar dengan sisi terpendek >= 600 pixel biasanya adalah Tablet/iPad
		if math.min(viewport.X, viewport.Y) >= 600 then
			return "Tablet"
		else
			return "Mobile"
		end
	end

	print("PC BOY")
	return "PC"
end

return DeviceHelper
