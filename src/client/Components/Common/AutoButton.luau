--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Roact = require(Packages:WaitForChild("Roact"))

local AUTO_PICKAXE_ICON = "rbxassetid://121306761895273"

local AutoButton = Roact.Component:extend("AutoButton")

function AutoButton:render()
	local isAutoActive = self.props.IsActive or false
	local onToggle = self.props.OnToggle
	local position = self.props.Position or UDim2.fromScale(0.5, 0.86)
	local size = self.props.Size or UDim2.fromScale(0.12, 0.045)
	local zIndex = self.props.ZIndex or 5

	return Roact.createElement("ImageButton", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = position,
		Size = size,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		ZIndex = zIndex,
		[Roact.Event.Activated] = function()
			if onToggle then
				onToggle()
			end
		end,
	}, {
		-- Mengunci rasio tombol auto agar bentuknya selalu presisi (3.6 : 1)
		UIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint", {
			AspectRatio = 3.6,
		}),

		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),

		-- Gradient Linear Kiri ke Kanan (Merah saat OFF, Hijau saat ON)
		UIGradient = Roact.createElement("UIGradient", {
			Color = if isAutoActive
				then ColorSequence.new({
					ColorSequenceKeypoint.new(0.0, Color3.fromHex("00FF44")), -- Left (Green)
					ColorSequenceKeypoint.new(1.0, Color3.fromHex("008F22")), -- Right (Dark Green)
				})
				else ColorSequence.new({
					ColorSequenceKeypoint.new(0.0, Color3.fromHex("E51B24")), -- Left (Bright Red)
					ColorSequenceKeypoint.new(1.0, Color3.fromHex("780206")), -- Right (Dark Red)
				}),
			Rotation = 0,
		}),

		-- White Outline Luar (Thickness 1)
		UIStroke = Roact.createElement("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
			Thickness = if isAutoActive then 1.5 else 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),

		-- Teks Status di Sisi Kiri (TextScaled)
		StatusText = Roact.createElement("TextLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0.08, 0.6),
			Size = UDim2.fromScale(0.64, 0.80),
			BackgroundTransparency = 1,
			Text = "AUTO",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Font = Enum.Font.LuckiestGuy,
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = zIndex + 1,
		}, {
			UIStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromRGB(0, 0, 0),
				Thickness = 1.5,
			}),
		}),

		-- Kontainer Ikon Mandiri di Sudut Kanan Luar (Anchor X: 1, Y: 0.5)
		IconContainer = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1.12, 0.3),
			Size = UDim2.fromScale(1, 1.5),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = zIndex + 2,
		}, {
			UIAspectRatioConstraint = Roact.createElement("UIAspectRatioConstraint", {
				AspectRatio = 1.0,
			}),
			IconImage = Roact.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Image = AUTO_PICKAXE_ICON,
				ScaleType = Enum.ScaleType.Fit,
				Active = false,
				ZIndex = zIndex + 3,
			}),
		}),
	})
end

return AutoButton
