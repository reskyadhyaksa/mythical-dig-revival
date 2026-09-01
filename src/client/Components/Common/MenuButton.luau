--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Packages = ReplicatedStorage.Packages
local Roact = require(Packages.Roact)

local TWEEN_ENTER_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TWEEN_LEAVE_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local MenuButton = Roact.Component:extend("MenuButton")

function MenuButton:init()
	self.buttonRef = Roact.createRef()
	self.iconRef = Roact.createRef()
	self.badgeRef = Roact.createRef()
end

function MenuButton:render()
	local layoutOrder = self.props.LayoutOrder or 1
	local image = self.props.Image or ""
	local fallbackEmoji = self.props.FallbackEmoji or "❓"
	local text = self.props.Text or ""
	local textColor3 = self.props.TextColor3 or Color3.fromRGB(255, 255, 255)
	local backgroundTransparency = self.props.BackgroundTransparency or 1
	local onActivated = self.props.OnActivated

	local hasImage = image ~= "" and image ~= "rbxassetid://0"

	local imageRotation = self.props.ImageRotation or self.props.Rotation or self.props.InitialRotation or 0
	local hoverOffset = self.props.HoverRotation or -10
	local hoverTargetRotation = imageRotation + hoverOffset

	return Roact.createElement("ImageButton", {
		[Roact.Ref] = self.buttonRef,
		LayoutOrder = layoutOrder,
		Size = UDim2.fromScale(0.9, 0.45),
		BackgroundTransparency = backgroundTransparency,
		AutoButtonColor = false,

		[Roact.Event.Activated] = function()
			if onActivated then
				onActivated()
			end
		end,

		[Roact.Event.MouseEnter] = function()
			local btn = self.buttonRef:getValue()
			local icon = self.iconRef:getValue()
			local badge = self.badgeRef:getValue()
			if btn then
				TweenService:Create(btn, TWEEN_ENTER_INFO, {
					Size = UDim2.fromScale(1.0, 0.5),
				}):Play()
			end
			if icon then
				TweenService:Create(icon, TWEEN_ENTER_INFO, {
					Rotation = hoverTargetRotation,
				}):Play()
			end
			if badge then
				TweenService:Create(badge, TWEEN_ENTER_INFO, {
					Position = UDim2.fromScale(0.42, 0.85),
				}):Play()
			end
		end,

		[Roact.Event.MouseLeave] = function()
			local btn = self.buttonRef:getValue()
			local icon = self.iconRef:getValue()
			local badge = self.badgeRef:getValue()
			if btn then
				TweenService:Create(btn, TWEEN_LEAVE_INFO, {
					Size = UDim2.fromScale(0.9, 0.45),
				}):Play()
			end
			if icon then
				TweenService:Create(icon, TWEEN_LEAVE_INFO, {
					Rotation = imageRotation,
				}):Play()
			end
			if badge then
				TweenService:Create(badge, TWEEN_LEAVE_INFO, {
					Position = UDim2.fromScale(0.5, 0.85),
				}):Play()
			end
		end,
	}, {
		UIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint", {
			AspectRatio = 1,
			AspectType = Enum.AspectType.FitWithinMaxSize,
			DominantAxis = Enum.DominantAxis.Width,
		}),

		IconImage = hasImage and Roact.createElement("ImageLabel", {
			[Roact.Ref] = self.iconRef,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = image,
			Rotation = imageRotation,
		}) or nil,

		IconText = not hasImage and Roact.createElement("TextLabel", {
			[Roact.Ref] = self.iconRef,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = fallbackEmoji,
			TextScaled = true,
			Rotation = imageRotation,
		}, {
			UITextSizeConstraint = Roact.createElement("UITextSizeConstraint", {
				MaxTextSize = 70,
				MinTextSize = 30,
			}),
		}) or nil,

		BadgeLabel = Roact.createElement("TextLabel", {
			[Roact.Ref] = self.badgeRef,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.85),
			Size = UDim2.new(1.15, 0, 0.28, 0),
			BackgroundTransparency = 1,
			Text = text,
			TextColor3 = textColor3,
			TextScaled = true,
			Font = Enum.Font.LuckiestGuy,
		}, {
			UITextSizeConstraint = Roact.createElement("UITextSizeConstraint", {
				MaxTextSize = 30,
				MinTextSize = 16,
			}),
			UIStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromRGB(0, 0, 0),
				Thickness = 1.5,
			}),
		}),
	})
end

return MenuButton
