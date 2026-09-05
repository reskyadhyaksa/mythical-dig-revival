--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Roact = require(Packages:WaitForChild("Roact"))
local DeviceHelper = require(ReplicatedStorage.Shared.Common.DeviceHelper)

local MobileDigButtonGui = Roact.Component:extend("MobileDigButtonGui")
local deviceType = DeviceHelper.GetDeviceType()

local SHOVEL_ICON = "rbxassetid://89491227108779"

function MobileDigButtonGui:init()
	self.state = {
		isPressed = false,
	}
end

function MobileDigButtonGui:render()
	local visible = self.props.Visible
	if visible == nil then
		visible = (UserInputService.TouchEnabled or deviceType == "Mobile" or deviceType == "Tablet")
	end

	if not visible then
		return nil
	end

	local isPressed = self.state.isPressed
	local onPress = self.props.OnPress
	local onRelease = self.props.OnRelease
	local isMinigameActive = self.props.IsMinigameActive or false

	local buttonSize = if deviceType == "Tablet" then UDim2.fromOffset(84, 84) else UDim2.fromOffset(72, 72)
	local buttonPos = if deviceType == "Tablet"
		then UDim2.new(1, -115, 1, -220)
		else UDim2.new(1, -95, 1, -195)

	local scale = if isPressed then 0.90 else 1.0

	return Roact.createElement("ScreenGui", {
		ResetOnSpawn = false,
		DisplayOrder = 15,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, {
		DigButtonWrapper = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(1, 1),
			Position = buttonPos,
			Size = buttonSize,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, {
			UIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint", {
				AspectRatio = 1.0,
			}),

			UIScale = Roact.createElement("UIScale", {
				Scale = scale,
			}),

			MainButton = Roact.createElement("ImageButton", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = if isPressed then 0.25 else 0.55,
				BorderSizePixel = 0,
				AutoButtonColor = false,

				[Roact.Event.InputBegan] = function(_rbx, input: InputObject)
					if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
						self:setState({ isPressed = true })
						if onPress then
							onPress()
						end
					end
				end,

				[Roact.Event.InputEnded] = function(_rbx, input: InputObject)
					if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
						self:setState({ isPressed = false })
						if onRelease then
							onRelease()
						end
					end
				end,
			}, {
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(1, 0),
				}),

				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromHex("#d9d9d9"),
					Transparency = if isPressed then 0.2 else 0.5,
					Thickness = 2,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}),

				-- Shovel Icon
				Icon = Roact.createElement("ImageLabel", {
					AnchorPoint = Vector2.new(0.5, 0.38),
					Position = UDim2.fromScale(0.5, 0.36),
					Size = UDim2.fromScale(0.52, 0.52),
					BackgroundTransparency = 1,
					Image = SHOVEL_ICON,
					ImageColor3 = Color3.fromHex("#d9d9d9"),
					ScaleType = Enum.ScaleType.Fit,
				}),

				-- Action Text (DIG / SWING)
				ActionLabel = Roact.createElement("TextLabel", {
					AnchorPoint = Vector2.new(0.5, 1),
					Position = UDim2.fromScale(0.5, 0.90),
					Size = UDim2.new(1, 0, 0.28, 0),
					BackgroundTransparency = 1,
					Font = Enum.Font.FredokaOne,
					Text = if isMinigameActive then "SWING" else "DIG",
					TextColor3 = Color3.fromHex("#d9d9d9"),
					TextScaled = true,
				}, {
					TextStroke = Roact.createElement("UIStroke", {
						Color = Color3.fromRGB(0, 0, 0),
						Transparency = 0.5,
						Thickness = 1.5,
					}),
				}),
			}),
		}),
	})
end

return MobileDigButtonGui
