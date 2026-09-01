--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Roact = require(Packages.Roact)

local StatBar = Roact.Component:extend("StatBar")

function StatBar:render()
	local layoutOrder = self.props.LayoutOrder or 1
	local image = self.props.Image or ""
	local fallbackEmoji = self.props.FallbackEmoji or "✨"
	local text = tostring(self.props.Text or "0")
	local iconSize = self.props.IconSize or 50
	local strokeColor = self.props.StrokeColor or Color3.fromRGB(241, 196, 15)
	local gradientStartColor = self.props.GradientStartColor or Color3.fromRGB(255, 215, 0)
	local gradientEndColor = self.props.GradientEndColor or Color3.fromRGB(40, 30, 10)
	local widthOffset = self.props.WidthOffset or 200

	local hasImage = image ~= "" and image ~= "rbxassetid://0"

	return Roact.createElement("Frame", {
		LayoutOrder = layoutOrder,
		Size = UDim2.fromOffset(widthOffset, iconSize),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, {
		-- Frame Kontainer (Dimulai dari AnchorPoint 0.5 X dari Icon = iconSize * 0.5)
		Container = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, iconSize * 0.5, 0.6, 0),
			Size = UDim2.new(1, -(iconSize * 0.5), 0, 38),
			BackgroundColor3 = Color3.fromRGB(20, 24, 35),
			BackgroundTransparency = 0.2,
			BorderSizePixel = 0,
			ZIndex = 1,
		}, {
			-- Stroke Garis Atas
			TopStroke = Roact.createElement("Frame", {
				Position = UDim2.new(0, 0, 0, 0),
				Size = UDim2.new(1, 0, 0, 2),
				BackgroundColor3 = strokeColor,
				BorderSizePixel = 0,
				ZIndex = 3,
			}),

			-- Stroke Garis Bawah
			BottomStroke = Roact.createElement("Frame", {
				Position = UDim2.new(0, 0, 1, -2),
				Size = UDim2.new(1, 0, 0, 2),
				BackgroundColor3 = strokeColor,
				BorderSizePixel = 0,
				ZIndex = 3,
			}),

			-- UIGradient dari Kiri ke Kanan
			UIGradient = Roact.createElement("UIGradient", {
				Rotation = 0,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, gradientStartColor),
					ColorSequenceKeypoint.new(1, gradientEndColor),
				}),
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.15),
					NumberSequenceKeypoint.new(1, 0.85),
				}),
			}),

			-- Label Teks (Sejajar Y-Axis)
			TextLabel = Roact.createElement("TextLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, (iconSize * 0.5) + 6, 0.5, 0),
				Size = UDim2.new(1, -((iconSize * 0.5) + 12), 1, 0),
				BackgroundTransparency = 1,
				Text = text,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				Font = Enum.Font.LuckiestGuy,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				ZIndex = 2,
			}, {
				UITextSizeConstraint = Roact.createElement("UITextSizeConstraint", {
					MaxTextSize = 22,
					MinTextSize = 14,
				}),
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromRGB(0, 0, 0),
					Thickness = 1.5,
				}),
			}),
		}),

		-- Icon Image / Fallback Emoji
		IconImage = hasImage and Roact.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.fromOffset(iconSize, iconSize),
			BackgroundTransparency = 1,
			Image = image,
			ZIndex = 4,
		}) or Roact.createElement("TextLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.fromOffset(iconSize, iconSize),
			BackgroundTransparency = 1,
			Text = fallbackEmoji,
			TextScaled = true,
			ZIndex = 4,
		}),
	})
end

return StatBar
