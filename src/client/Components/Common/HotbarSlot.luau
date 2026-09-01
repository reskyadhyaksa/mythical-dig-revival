--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Packages = ReplicatedStorage.Packages
local Roact = require(Packages.Roact)

local TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local HotbarSlot = Roact.Component:extend("HotbarSlot")

function HotbarSlot:init()
	self.btnRef = Roact.createRef()
end

function HotbarSlot:render()
	local layoutOrder = self.props.LayoutOrder or 1
	local keyText = self.props.KeyText or "1"
	local image = self.props.Image or ""
	local fallbackEmoji = self.props.FallbackEmoji or "❓"
	local isActive = self.props.IsActive or false
	local onActivated = self.props.OnActivated

	local hasImage = image ~= "" and image ~= "rbxassetid://0"

	local borderColor = if isActive then Color3.fromRGB(255, 215, 0) else Color3.fromRGB(60, 70, 90)
	local strokeThickness = if isActive then 2.5 else 1.5

	local count = self.props.Count

	return Roact.createElement("ImageButton", {
		[Roact.Ref] = self.btnRef,
		LayoutOrder = layoutOrder,
		Size = UDim2.fromOffset(60, 60),
		BackgroundColor3 = Color3.fromRGB(25, 30, 45),
		BackgroundTransparency = 0.2,
		AutoButtonColor = false,

		[Roact.Event.Activated] = function()
			if onActivated then
				onActivated()
			end
		end,

		[Roact.Event.MouseEnter] = function()
			local btn = self.btnRef:getValue()
			if btn then
				TweenService:Create(btn, TWEEN_INFO, {
					Size = UDim2.fromOffset(66, 66),
				}):Play()
			end
		end,

		[Roact.Event.MouseLeave] = function()
			local btn = self.btnRef:getValue()
			if btn then
				TweenService:Create(btn, TWEEN_INFO, {
					Size = UDim2.fromOffset(60, 60),
				}):Play()
			end
		end,
	}, {
		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 12),
		}),

		UIStroke = Roact.createElement("UIStroke", {
			Color = borderColor,
			Thickness = strokeThickness,
		}),

		-- Icon Gambar / Emoji
		Icon = hasImage and Roact.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.55),
			Size = UDim2.fromOffset(36, 36),
			BackgroundTransparency = 1,
			Image = image,
			Active = false,
		}) or Roact.createElement("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.55),
			Size = UDim2.fromOffset(36, 36),
			BackgroundTransparency = 1,
			Text = fallbackEmoji,
			TextScaled = true,
			Active = false,
		}),

		-- Badge Shortcut Keybind [1], [2], [3]
		KeyBadge = Roact.createElement("Frame", {
			Position = UDim2.new(0, 4, 0, 4),
			Size = UDim2.fromOffset(18, 18),
			BackgroundColor3 = Color3.fromRGB(15, 20, 30),
			BackgroundTransparency = 0.2,
			BorderSizePixel = 0,
			Active = false,
			ZIndex = 5,
		}, {
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 4),
			}),
			UIStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromRGB(100, 110, 130),
				Thickness = 1,
			}),
			KeyText = Roact.createElement("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = keyText,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				Font = Enum.Font.GothamBold,
				Active = false,
			}),
		}),

		-- Badge Jumlah Item (misal x5)
		CountBadge = count and count > 1 and Roact.createElement("TextLabel", {
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -4, 1, -4),
			Size = UDim2.fromOffset(28, 16),
			BackgroundTransparency = 1,
			Text = string.format("x%d", count),
			TextColor3 = Color3.fromRGB(255, 215, 0),
			TextScaled = true,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Right,
			Active = false,
			ZIndex = 5,
		}, {
			UIStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromRGB(0, 0, 0),
				Thickness = 1.5,
			}),
		}) or nil,
	})
end

return HotbarSlot
