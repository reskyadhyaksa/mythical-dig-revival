--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Roact = require(Packages:WaitForChild("Roact"))
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local dataFolder = sharedFolder:WaitForChild("Data")
local commonFolder = sharedFolder:WaitForChild("Common")
local Items = require(dataFolder:WaitForChild("Items")) :: any
local ItemHelper = require(commonFolder:WaitForChild("ItemHelper")) :: any
local LevelConfig = require(dataFolder:WaitForChild("LevelConfig")) :: any

local InventoryGui = Roact.Component:extend("InventoryGui")

local RarityColors = {
	Common = Color3.fromRGB(180, 180, 180),
	Uncommon = Color3.fromRGB(46, 204, 113),
	Rare = Color3.fromRGB(52, 152, 219),
	Epic = Color3.fromRGB(155, 89, 182),
	Legendary = Color3.fromRGB(241, 196, 15),
	Secret = Color3.fromRGB(231, 76, 60),
}

function InventoryGui:init()
	self.state = {
		visibleLimit = 36, -- Render 36 item pertama saat GUI dibuka
	}
end

function InventoryGui:render()
	local inventory = self.props.Inventory or {}
	local level = self.props.Level or 0
	local coins = self.props.Coins or 0
	local onClose = self.props.OnClose
	local onSellItem = self.props.OnSellItem
	local onSellAll = self.props.OnSellAll

	local visibleLimit = self.state.visibleLimit or 36
	local maxCapacity = LevelConfig.GetMaxInventoryCapacity(level)
	local totalItems = 0
	local totalWeight = 0
	local totalValue = 0
	local itemCards = {}

	for index, itemData in ipairs(inventory) do
		local itemId = if typeof(itemData) == "table" then itemData.ItemId else itemData
		local uuid = if typeof(itemData) == "table" then itemData.UUID else tostring(index)
		local weight = if typeof(itemData) == "table" and itemData.Weight then itemData.Weight else ItemHelper.GetItemWeight(itemId)

		totalItems += 1
		local unitPrice = ItemHelper.GetSellPrice(itemId)
		totalValue += unitPrice
		totalWeight += weight

		-- Batch Lazy Load: Hanya buat elemen UI untuk item dalam batas visibleLimit
		if index <= visibleLimit then
			local itemDef = Items.Dict[itemId] or { Name = itemId, Rarity = "Common" }
			local rarityColor = RarityColors[itemDef.Rarity] or RarityColors.Common
			local cardKey = uuid or string.format("%s_%d", itemId, index)

			local isGiant = ItemHelper.IsMaxTon(itemId, weight)
			local weightTag = if isGiant then string.format("🌟 MAX TON (%.1fkg)", weight) else string.format("⚖️ %.1fkg", weight)

			itemCards[cardKey] = Roact.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(28, 33, 46),
				BorderSizePixel = 0,
			}, {
				UICorner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
				UIStroke = Roact.createElement("UIStroke", {
					Color = rarityColor,
					Thickness = 1.5,
				}),

				-- Item Name
				NameLabel = Roact.createElement("TextLabel", {
					Position = UDim2.fromOffset(10, 10),
					Size = UDim2.new(1, -20, 0, 25),
					BackgroundTransparency = 1,
					Text = itemDef.Name,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 14,
					Font = Enum.Font.GothamBold,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),

				-- Rarity Tag, Unit Price & Unit Weight (Termasuk Indikator MAX TON)
				DetailsLabel = Roact.createElement("TextLabel", {
					Position = UDim2.fromOffset(10, 36),
					Size = UDim2.new(1, -20, 0, 20),
					BackgroundTransparency = 1,
					Text = string.format("%s • 💰 %d • %s", string.upper(itemDef.Rarity), unitPrice, weightTag),
					TextColor3 = isGiant and Color3.fromRGB(255, 215, 0) or rarityColor,
					TextSize = 10,
					Font = Enum.Font.GothamMedium,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),

				-- Sell Button per Unique Item
				SellButton = Roact.createElement("TextButton", {
					Position = UDim2.fromOffset(10, 68),
					Size = UDim2.new(1, -20, 0, 30),
					BackgroundColor3 = Color3.fromRGB(46, 204, 113),
					Text = string.format("SELL (💰 %d)", unitPrice),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					Font = Enum.Font.GothamBold,

					[Roact.Event.Activated] = function()
						if onSellItem then onSellItem(uuid or itemId, 1) end
					end,
				}, {
					UICorner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
				}),
			})
		end
	end

	local isFull = totalItems >= maxCapacity

	return Roact.createElement("ScreenGui", {
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
	}, {
		-- Overlay Background
		Overlay = Roact.createElement("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.55,
			Active = true,
		}),

		-- Main Inventory Window
		MainFrame = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(560, 420),
			BackgroundColor3 = Color3.fromRGB(18, 22, 30),
			BorderSizePixel = 0,
		}, {
			UICorner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 16) }),
			UIStroke = Roact.createElement("UIStroke", {
				Color = isFull and Color3.fromRGB(231, 76, 60) or Color3.fromRGB(52, 152, 219),
				Thickness = 2,
			}),

			-- Header Banner
			HeaderFrame = Roact.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, 60),
				BackgroundColor3 = Color3.fromRGB(26, 32, 44),
				BorderSizePixel = 0,
			}, {
				UICorner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 16) }),

				Title = Roact.createElement("TextLabel", {
					Position = UDim2.fromOffset(20, 0),
					Size = UDim2.new(0.4, 0, 1, 0),
					BackgroundTransparency = 1,
					Text = "🎒 INVENTORY",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 20,
					Font = Enum.Font.GothamBlack,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),

				-- Capacity & Weight Pill Badge
				CapacityBadge = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -160, 0.5, 0),
					Size = UDim2.fromOffset(180, 32),
					BackgroundColor3 = Color3.fromRGB(12, 15, 22),
				}, {
					UICorner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 16) }),
					CapacityText = Roact.createElement("TextLabel", {
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						Text = string.format("📦 %d/%d • ⚖️ %.1fkg", totalItems, maxCapacity, totalWeight),
						TextColor3 = isFull and Color3.fromRGB(231, 76, 60) or Color3.fromRGB(46, 204, 113),
						TextSize = 11,
						Font = Enum.Font.GothamBold,
					}),
				}),

				-- Coins Pill
				CoinsBadge = Roact.createElement("Frame", {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -55, 0.5, 0),
					Size = UDim2.fromOffset(95, 32),
					BackgroundColor3 = Color3.fromRGB(12, 15, 22),
				}, {
					UICorner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 16) }),
					CoinsText = Roact.createElement("TextLabel", {
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						Text = string.format("💰 %d", coins),
						TextColor3 = Color3.fromRGB(255, 215, 0),
						TextSize = 12,
						Font = Enum.Font.GothamBold,
					}),
				}),

				-- Close Button
				CloseButton = Roact.createElement("TextButton", {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -12, 0.5, 0),
					Size = UDim2.fromOffset(34, 34),
					BackgroundColor3 = Color3.fromRGB(231, 76, 60),
					Text = "✕",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 18,
					Font = Enum.Font.GothamBlack,

					[Roact.Event.Activated] = function()
						if onClose then onClose() end
					end,
				}, {
					UICorner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 17) }),
				}),
			}),

			-- Sell All Header Action Bar
			ActionBar = Roact.createElement("Frame", {
				Position = UDim2.fromOffset(15, 70),
				Size = UDim2.new(1, -30, 0, 40),
				BackgroundTransparency = 1,
			}, {
				SellAllButton = Roact.createElement("TextButton", {
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = Color3.fromRGB(46, 204, 113),
					Text = string.format("💰 SELL EVERYTHING (VALUED AT %d COINS)", totalValue),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 14,
					Font = Enum.Font.GothamBlack,
					AutoButtonColor = totalValue > 0,

					[Roact.Event.Activated] = function()
						if totalValue > 0 and onSellAll then
							onSellAll()
						end
					end,
				}, {
					UICorner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
				}),
			}),

			-- Item Grid Container with Infinite Scroll / Lazy Loading
			ScrollContainer = Roact.createElement("ScrollingFrame", {
				Position = UDim2.fromOffset(15, 120),
				Size = UDim2.new(1, -30, 1, -135),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 6,
				ScrollBarImageColor3 = Color3.fromRGB(52, 152, 219),
				CanvasSize = UDim2.fromScale(0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,

				-- Batch Lazy Load saat scroll mendekati bawah (75% scroll limit)
				[Roact.Change.CanvasPosition] = function(rbx: ScrollingFrame)
					local totalCount = #inventory
					local currentLimit = self.state.visibleLimit or 36
					if currentLimit >= totalCount then
						return
					end

					local canvasHeight = rbx.AbsoluteCanvasSize.Y
					local windowHeight = rbx.AbsoluteWindowSize.Y
					local maxScroll = math.max(1, canvasHeight - windowHeight)
					local currentScroll = rbx.CanvasPosition.Y

					if currentScroll >= maxScroll * 0.75 then
						self:setState(function(prevState)
							return {
								visibleLimit = math.min(totalCount, (prevState.visibleLimit or 36) + 24),
							}
						end)
					end
				end,
			}, ObjectAssign({
				UIGridLayout = Roact.createElement("UIGridLayout", {
					CellSize = UDim2.fromOffset(160, 110),
					CellPadding = UDim2.fromOffset(15, 15),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
			}, itemCards)),
		}),
	})
end

function ObjectAssign(target, source)
	for k, v in pairs(source) do
		target[k] = v
	end
	return target
end

return InventoryGui
