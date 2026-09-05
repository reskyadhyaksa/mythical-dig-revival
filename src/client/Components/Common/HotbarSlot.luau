--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local packagesFolder = ReplicatedStorage:WaitForChild("Packages")
local DeviceHelper = require(ReplicatedStorage.Shared.Common.DeviceHelper)
local Roact = require(packagesFolder:WaitForChild("Roact"))

local TWEEN_INFO = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local HotbarSlot = Roact.Component:extend("HotbarSlot")
local deviceType = DeviceHelper.GetDeviceType()

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
	local count = self.props.Count
	local sizeButton = if deviceType == "Mobile" then UDim2.fromScale(1, 1) else UDim2.fromScale(0.85, 0.85)
	local thicknessMobile = if isActive then 2 else 1
	local thicknessOther = if isActive then 4 else 3

	local iconPosition = self.props.IconPosition or UDim2.fromScale(0.5, 0.52)
	local iconSizeProp = self.props.IconSize
	local iconSize: UDim2 = if typeof(iconSizeProp) == "UDim2"
		then iconSizeProp
		elseif typeof(iconSizeProp) == "number" then (if iconSizeProp <= 1
			then UDim2.fromScale(iconSizeProp, iconSizeProp)
			else UDim2.fromOffset(iconSizeProp, iconSizeProp))
		else UDim2.fromScale(0.68, 0.68)

	return Roact.createElement("ImageButton", {
		[Roact.Ref] = self.btnRef,
		LayoutOrder = layoutOrder,
		Size = self.props.Size or sizeButton,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0,
		AutoButtonColor = false,
		ZIndex = 2,

		[Roact.Event.Activated] = function()
			if onActivated then
				onActivated()
			end
		end,

		[Roact.Event.MouseEnter] = function()
			local btn = self.btnRef:getValue()
			if btn then
				TweenService:Create(btn, TWEEN_INFO, {
					Size = UDim2.fromScale(0.92, 0.92),
				}):Play()
			end
		end,

		[Roact.Event.MouseLeave] = function()
			local btn = self.btnRef:getValue()
			if btn then
				TweenService:Create(btn, TWEEN_INFO, {
					Size = self.props.Size or UDim2.fromScale(0.85, 0.85),
				}):Play()
			end
		end,
	}, {
		-- 1. Aspek Rasio Persegi 1:1
		UIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint", {
			AspectRatio = 1.0,
		}),

		-- 2. Rounded 5px pada Main Large Container
		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),

		-- 3. Linear Gradient dari Atas (#59C5F3) ke Bawah (#1C9DDE)
		UIGradient = Roact.createElement("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.0, Color3.fromHex("#00a9f1")), -- Top
				ColorSequenceKeypoint.new(1.0, Color3.fromHex("#036291")), -- Bottom
			}),
			Rotation = 90,
		}),

		-- 4. Outline Luar (Thickness 1)
		UIStroke = Roact.createElement("UIStroke", {
			Color = if isActive then Color3.fromRGB(255, 255, 255) else Color3.fromHex("#073f5b"),
			Thickness = if deviceType == "Mobile" then thicknessMobile else thicknessOther,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),

		-- 5. Icon Gambar / Emoji di Tengah
		Icon = hasImage and Roact.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = iconPosition,
			Size = iconSize,
			BackgroundTransparency = 1,
			Image = image,
			ScaleType = Enum.ScaleType.Fit,
			Active = false,
			ZIndex = 3,
		}) or Roact.createElement("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = iconPosition,
			Size = iconSize,
			BackgroundTransparency = 1,
			Text = fallbackEmoji,
			TextScaled = true,
			Active = false,
			ZIndex = 3,
		}),

		-- 6. Little Container Keybind Badge di Anchor (0, 0)
		KeyBadge = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.3, 0.3),
			Position = UDim2.fromScale(0, 0),
			Size = UDim2.fromScale(0.36, 0.36),
			BackgroundColor3 = Color3.fromHex("13638D"), -- Deep Dark Blue
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			Active = false,
			ZIndex = 6,
		}, {
			UIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint", {
				AspectRatio = 1.0,
			}),
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 4),
			}),
			UIStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromHex("27A4E2"),
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			KeyText = Roact.createElement("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.6),
				Size = UDim2.fromScale(0.85, 0.85),
				BackgroundTransparency = 1,
				Text = keyText,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				Font = Enum.Font.LuckiestGuy,
				Active = false,
				ZIndex = 7,
			}),
		}),

		-- 7. Badge Jumlah Item (misal x5)
		CountBadge = count and count > 1 and Roact.createElement("TextLabel", {
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.fromScale(0.95, 0.95),
			Size = UDim2.fromScale(0.5, 0.3),
			BackgroundTransparency = 1,
			Text = string.format("x%d", count),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			Font = Enum.Font.LuckiestGuy,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Bottom,
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
