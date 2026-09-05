--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Roact = require(Packages:WaitForChild("Roact"))

local CompassBarButton = Roact.Component:extend("CompassBarButton")

export type Props = {
	Id: string?,
	Label: string,
	Icon: string,
	LayoutOrder: number?,
	Size: UDim2?,
	IconSize: UDim2?,
	OnActivated: (() -> ())?,
	DeviceType: string?,
}

type State = {
	IsHovered: boolean,
	IsPressed: boolean,
}

function CompassBarButton:init()
	self.state = {
		IsHovered = false,
		IsPressed = false,
	}
end

function CompassBarButton:render()
	local isMobile = self.props.DeviceType == "Mobile"
	local size = self.props.Size or if isMobile then UDim2.fromScale(0.44, 0.90) else UDim2.fromScale(0.44, 0.90)
	local iconSize = self.props.IconSize or if isMobile then UDim2.fromScale(0.75, 0.75) else UDim2.fromScale(0.8, 0.8)
	local isPressed = self.state.IsPressed
	local isHovered = self.state.IsHovered

	local scaleMultiplier = if isPressed then 0.90 else (if isHovered then 1.08 else 1.0)

	return Roact.createElement("ImageButton", {
		LayoutOrder = self.props.LayoutOrder or 1,
		Size = size,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		[Roact.Event.Activated] = function()
			if self.props.OnActivated then
				self.props.OnActivated()
			end
		end,
		[Roact.Event.MouseEnter] = function()
			self:setState({ IsHovered = true })
		end,
		[Roact.Event.MouseLeave] = function()
			self:setState({ IsHovered = false, IsPressed = false })
		end,
		[Roact.Event.MouseButton1Down] = function()
			self:setState({ IsPressed = true })
		end,
		[Roact.Event.MouseButton1Up] = function()
			self:setState({ IsPressed = false })
		end,
	}, {
		UIScale = Roact.createElement("UIScale", {
			Scale = scaleMultiplier,
		}),

		-- Icon Gambar di Bagian Atas
		IconImage = Roact.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, -0.05),
			Size = iconSize,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = self.props.Icon,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 5,
		}),

		-- Label Teks di Bagian Bawah dengan Stroke Gelap (Ukuran Konsisten)
		TextLabel = Roact.createElement("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, if isMobile then 1.15 else 1.1),
			Size = UDim2.fromScale(1.8, 0.42),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = self.props.Label,
			Font = Enum.Font.LuckiestGuy,
			TextSize = if isMobile then 8 else 13,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 5,
		}, {
			UIStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromHex("00385e"),
				Thickness = if isMobile then 1.5 else 2.0,
			}),
		}),
	})
end

return CompassBarButton
