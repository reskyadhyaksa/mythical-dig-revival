--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local packagesFolder = ReplicatedStorage:WaitForChild("Packages")
local Roact = require(packagesFolder:WaitForChild("Roact"))
local MenuButton = require(script.Parent.Common.MenuButton)

local RightMenuGui = Roact.Component:extend("RightMenuGui")

function RightMenuGui:render()
	local onOpenInventory = self.props.OnOpenInventory
	local onOpenShop = self.props.OnOpenShop

	local inventoryImage: string = "rbxassetid://81621266214171"
	local shopImage: string = "rbxassetid://131110815703277"

	return Roact.createElement("ScreenGui", {
		ResetOnSpawn = false,
	}, {
		SidebarFrame = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -15, 0.5, 0),
			Size = UDim2.fromScale(0.08, 0.45),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, {
			UISizeConstraint = Roact.createElement("UISizeConstraint", {
				MinSize = Vector2.new(90, 200),
				MaxSize = Vector2.new(150, 320),
			}),

			UIListLayout = Roact.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0.02, 0.1),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			InventoryButton = Roact.createElement(MenuButton, {
				LayoutOrder = 1,
				Image = inventoryImage,
				FallbackEmoji = "🎒",
				Text = "INVENTORY",
				Rotation = -20,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				OnActivated = onOpenInventory,
			}),

			ShovelShopButton = Roact.createElement(MenuButton, {
				LayoutOrder = 2,
				Image = shopImage,
				FallbackEmoji = "⚒️",
				Text = "SHOP",
				TextColor3 = Color3.fromRGB(255, 215, 0),
				BackgroundTransparency = 1,
				OnActivated = onOpenShop,
			}),
		}),
	})
end

return RightMenuGui
