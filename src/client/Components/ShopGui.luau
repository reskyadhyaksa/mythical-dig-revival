--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Roact = require(Packages.Roact)
local Shovels = require(ReplicatedStorage.Shared.Data.Shovels) :: any

local ShopGui = Roact.Component:extend("ShopGui")

function ShopGui:render()
	local coins = self.props.Coins or 0
	local equippedShovel = self.props.EquippedShovel or "WoodenShovel"
	local ownedShovels = self.props.OwnedShovels or { "WoodenShovel" }
	local onClose = self.props.OnClose
	local onBuy = self.props.OnBuy
	local onEquip = self.props.OnEquip

	local shovelCards = {}

	for shovelId, shovelDef in pairs(Shovels.Dict) do
		local isOwned = table.find(ownedShovels, shovelId) ~= nil
		local isEquipped = (equippedShovel == shovelId)

		-- Button text & color determination
		local btnText = "BUY"
		local btnColor = Color3.fromRGB(241, 196, 15) -- Gold
		local btnTextColor = Color3.fromRGB(40, 30, 0)

		if isEquipped then
			btnText = "EQUIPPED"
			btnColor = Color3.fromRGB(46, 204, 113) -- Emerald Green
			btnTextColor = Color3.fromRGB(255, 255, 255)
		elseif isOwned then
			btnText = "EQUIP"
			btnColor = Color3.fromRGB(52, 152, 219) -- Cyan Blue
			btnTextColor = Color3.fromRGB(255, 255, 255)
		else
			btnText = string.format("💰 %d", shovelDef.Price)
		end

		shovelCards[shovelId] = Roact.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(30, 35, 48),
			BorderSizePixel = 0,
		}, {
			UICorner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
			UIStroke = Roact.createElement("UIStroke", {
				Color = isEquipped and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(60, 70, 95),
				Thickness = isEquipped and 2 or 1,
			}),

			-- Title
			TitleLabel = Roact.createElement("TextLabel", {
				Position = UDim2.fromOffset(10, 10),
				Size = UDim2.new(1, -20, 0, 25),
				BackgroundTransparency = 1,
				Text = shovelDef.Name,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 16,
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),

			-- Stats Frame
			StatsFrame = Roact.createElement("Frame", {
				Position = UDim2.fromOffset(10, 40),
				Size = UDim2.new(1, -20, 0, 45),
				BackgroundTransparency = 1,
			}, {
				PowerLabel = Roact.createElement("TextLabel", {
					Position = UDim2.fromScale(0, 0),
					Size = UDim2.new(1, 0, 0, 20),
					BackgroundTransparency = 1,
					Text = string.format("⚡ Power: +%d", shovelDef.DigPower),
					TextColor3 = Color3.fromRGB(241, 196, 15),
					TextSize = 13,
					Font = Enum.Font.GothamMedium,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
				SpeedLabel = Roact.createElement("TextLabel", {
					Position = UDim2.fromScale(0, 0.5),
					Size = UDim2.new(1, 0, 0, 20),
					BackgroundTransparency = 1,
					Text = string.format("⏱️ Cooldown: %.2fs", shovelDef.SwingCooldown),
					TextColor3 = Color3.fromRGB(52, 152, 219),
					TextSize = 13,
					Font = Enum.Font.GothamMedium,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
			}),

			-- Action Button
			ActionButton = Roact.createElement("TextButton", {
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -10),
				Size = UDim2.new(1, -20, 0, 36),
				BackgroundColor3 = btnColor,
				Text = btnText,
				TextColor3 = btnTextColor,
				TextSize = 14,
				Font = Enum.Font.GothamBlack,
				AutoButtonColor = not isEquipped,

				[Roact.Event.Activated] = function()
					if isEquipped then
						return
					elseif isOwned then
						if onEquip then onEquip(shovelId) end
					else
						if onBuy then onBuy(shovelId) end
					end
				end,
			}, {
				UICorner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
			}),
		})
	end

	return Roact.createElement("ScreenGui", {
		ResetOnSpawn = false,
	}, {
		-- Dark Overlay Background
		Overlay = Roact.createElement("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.55,
			Active = true,
		}),

		-- Main Shop Window
		MainFrame = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(540, 400),
			BackgroundColor3 = Color3.fromRGB(20, 24, 33),
			BorderSizePixel = 0,
		}, {
			UICorner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 16) }),
			UIStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromRGB(241, 196, 15),
				Thickness = 2,
			}),

			-- Header Banner
			HeaderFrame = Roact.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, 60),
				BackgroundColor3 = Color3.fromRGB(28, 34, 48),
				BorderSizePixel = 0,
			}, {
				UICorner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 16) }),

				Title = Roact.createElement("TextLabel", {
					Position = UDim2.fromOffset(20, 0),
					Size = UDim2.new(0.5, 0, 1, 0),
					BackgroundTransparency = 1,
					Text = "⚒️ SHOVEL SHOP",
					TextColor3 = Color3.fromRGB(241, 196, 15),
					TextSize = 22,
					Font = Enum.Font.GothamBlack,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),

				-- Coins Pill
				CoinsBadge = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -60, 0.5, 0),
					Size = UDim2.fromOffset(140, 32),
					BackgroundColor3 = Color3.fromRGB(15, 18, 26),
				}, {
					UICorner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 16) }),
					CoinsText = Roact.createElement("TextLabel", {
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						Text = string.format("💰 %d", coins),
						TextColor3 = Color3.fromRGB(255, 215, 0),
						TextSize = 14,
						Font = Enum.Font.GothamBold,
					}),
				}),

				-- Close Button
				CloseButton = Roact.createElement("TextButton", {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -12, 0.5, 0),
					Size = UDim2.fromOffset(36, 36),
					BackgroundColor3 = Color3.fromRGB(231, 76, 60),
					Text = "✕",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 18,
					Font = Enum.Font.GothamBlack,

					[Roact.Event.Activated] = function()
						if onClose then onClose() end
					end,
				}, {
					UICorner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 18) }),
				}),
			}),

			-- Scrolling Grid Container
			ScrollContainer = Roact.createElement("ScrollingFrame", {
				Position = UDim2.fromOffset(15, 75),
				Size = UDim2.new(1, -30, 1, -90),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 6,
				ScrollBarImageColor3 = Color3.fromRGB(241, 196, 15),
				CanvasSize = UDim2.fromScale(0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
			}, ObjectAssign({
				UIGridLayout = Roact.createElement("UIGridLayout", {
					CellSize = UDim2.fromOffset(155, 140),
					CellPadding = UDim2.fromOffset(15, 15),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
			}, shovelCards)),
		}),
	})
end

function ObjectAssign(target, source)
	for k, v in pairs(source) do
		target[k] = v
	end
	return target
end

return ShopGui
