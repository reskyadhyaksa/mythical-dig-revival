--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Roact = require(Packages.Roact)

local SideMenuGui = Roact.Component:extend("SideMenuGui")

function SideMenuGui:render()
	local onOpenInventory = self.props.OnOpenInventory
	local onOpenShop = self.props.OnOpenShop

	return Roact.createElement("ScreenGui", {
		ResetOnSpawn = false,
	}, {
		-- Left Sidebar Frame Container
		SidebarFrame = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 15, 0.5, 0),
			Size = UDim2.fromOffset(70, 160),
			BackgroundColor3 = Color3.fromRGB(20, 24, 33),
			BackgroundTransparency = 0.25,
			BorderSizePixel = 0,
		}, {
			UICorner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 16) }),
			UIStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromRGB(52, 152, 219),
				Thickness = 1.5,
			}),
			UIListLayout = Roact.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 12),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			-- Inventory Button
			InventoryButton = Roact.createElement("ImageButton", {
				LayoutOrder = 1,
				Size = UDim2.fromOffset(50, 50),
				BackgroundColor3 = Color3.fromRGB(30, 36, 50),
				Image = "rbxassetid://0", -- Dummy AssetID (dapat diisi ID gambar kemudian)
				AutoButtonColor = true,

				[Roact.Event.Activated] = function()
					if onOpenInventory then onOpenInventory() end
				end,
			}, {
				UICorner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromRGB(46, 204, 113),
					Thickness = 1,
				}),

				-- Fallback Emoji / Label Text jika AssetID belum diisi
				IconText = Roact.createElement("TextLabel", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = "🎒",
					TextSize = 24,
				}),

				-- Tooltip Badge (Di bawah ikon)
				BadgeLabel = Roact.createElement("TextLabel", {
					AnchorPoint = Vector2.new(0.5, 1),
					Position = UDim2.new(0.5, 0, 1, -2),
					Size = UDim2.new(1, 0, 0, 12),
					BackgroundTransparency = 1,
					Text = "BAG",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 9,
					Font = Enum.Font.GothamBlack,
				}),
			}),

			-- Shovel Shop Button
			ShovelShopButton = Roact.createElement("ImageButton", {
				LayoutOrder = 2,
				Size = UDim2.fromOffset(50, 50),
				BackgroundColor3 = Color3.fromRGB(30, 36, 50),
				Image = "rbxassetid://0", -- Dummy AssetID (dapat diisi ID gambar kemudian)
				AutoButtonColor = true,

				[Roact.Event.Activated] = function()
					if onOpenShop then onOpenShop() end
				end,
			}, {
				UICorner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
				UIStroke = Roact.createElement("UIStroke", {
					Color = Color3.fromRGB(241, 196, 15),
					Thickness = 1,
				}),

				-- Fallback Emoji / Label Text jika AssetID belum diisi
				IconText = Roact.createElement("TextLabel", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = "⚒️",
					TextSize = 24,
				}),

				-- Tooltip Badge (Di bawah ikon)
				BadgeLabel = Roact.createElement("TextLabel", {
					AnchorPoint = Vector2.new(0.5, 1),
					Position = UDim2.new(0.5, 0, 1, -2),
					Size = UDim2.new(1, 0, 0, 12),
					BackgroundTransparency = 1,
					Text = "SHOP",
					TextColor3 = Color3.fromRGB(255, 215, 0),
					TextSize = 9,
					Font = Enum.Font.GothamBlack,
				}),
			}),
		}),
	})
end

return SideMenuGui
