--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local packagesFolder = ReplicatedStorage:WaitForChild("Packages")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local Roact = require(packagesFolder:WaitForChild("Roact"))
local StatBar = require(script.Parent.Common.StatBar)
local DeviceHelper = require(sharedFolder:WaitForChild("Common"):WaitForChild("DeviceHelper"))

local StatsHudGui = Roact.Component:extend("StatsHudGui")

local function formatNumber(n: number): string
	local formatted = tostring(math.floor(n))
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then
			break
		end
	end
	return formatted
end

function StatsHudGui:render()
	local coins = self.props.Coins or 0
	local luck = self.props.Luck or "+100%"
	local coinImage = "rbxassetid://122992611665292"
	local luckImage = "rbxassetid://100488739842115"

	local deviceType = DeviceHelper.GetDeviceType()
	local sizeContainer = if deviceType == "Mobile" then UDim2.fromScale(0.165, 0.25) else UDim2.fromScale(0.18, 0.2)

	return Roact.createElement("ScreenGui", {
		ResetOnSpawn = false,
	}, {
		ListContainer = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0.01, 0, 0.95, 0),
			Size = sizeContainer,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, {
			UIListLayout = Roact.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0.125, 0),
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
			}),

			-- 1. StatBar Luck (Atas)
			LuckBar = Roact.createElement(StatBar, {
				LayoutOrder = 1,
				Image = luckImage,
				FallbackEmoji = "🍀",
				Text = typeof(luck) == "number" and string.format("+%d%% Luck", luck) or tostring(luck),
				StrokeColor = Color3.fromRGB(46, 204, 113), -- Hijau Emerald
				GradientStartColor = Color3.fromRGB(46, 204, 113),
				GradientEndColor = Color3.fromRGB(15, 60, 30),
			}),

			-- 2. StatBar Coins (Bawah)
			CoinBar = Roact.createElement(StatBar, {
				LayoutOrder = 2,
				Image = coinImage,
				FallbackEmoji = "🪙",
				Text = formatNumber(coins),
				StrokeColor = Color3.fromRGB(241, 196, 15), -- Emas
				GradientStartColor = Color3.fromRGB(241, 196, 15),
				GradientEndColor = Color3.fromRGB(60, 45, 10),
			}),
		}),
	})
end

return StatsHudGui
