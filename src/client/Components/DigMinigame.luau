--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Roact = require(Packages.Roact)

local DigMinigame = Roact.Component:extend("DigMinigame")

function DigMinigame:init()
	self.startTime = os.clock()
	self.state = {
		timeRemaining = self.props.TimeLimit or 15,
	}
end

function DigMinigame:didMount()
	self.running = true
	task.spawn(function()
		while self.running do
			task.wait(0.2)
			if not self.running then
				break
			end

			local elapsed = os.clock() - self.startTime
			local timeLimit = self.props.TimeLimit or 15
			local remaining = math.max(0, math.ceil(timeLimit - elapsed))

			self:setState({
				timeRemaining = remaining,
			})

			if remaining <= 0 then
				if self.props.OnCancel then
					self.props.OnCancel()
				end
				break
			end
		end
	end)
end

function DigMinigame:willUnmount()
	self.running = false
end

function DigMinigame:render()
	local currentHp = self.props.CurrentHp or 100
	local maxHp = self.props.MaxHp or 100
	local rarity = self.props.Rarity or "Common"
	local itemName = self.props.ItemName or "Unknown Item"
	local minPower = self.props.MinDigPower or 5
	local shovelPower = self.props.ShovelPower or 10
	local isTooWeak = self.props.IsTooWeak or false
	local onSwing = self.props.OnSwing
	local onCancel = self.props.OnCancel
	local timeRemaining = self.state.timeRemaining

	local hpPercent = math.clamp(currentHp / maxHp, 0, 1)

	local rarityColors = {
		Common = Color3.fromRGB(180, 180, 180),
		Uncommon = Color3.fromRGB(46, 204, 113),
		Rare = Color3.fromRGB(52, 152, 219),
		Epic = Color3.fromRGB(155, 89, 182),
		Legendary = Color3.fromRGB(241, 196, 15),
		Secret = Color3.fromRGB(231, 76, 60),
	}

	local activeColor = rarityColors[rarity] or rarityColors.Common

	local btnText = isTooWeak and "❌ SHOVEL TOO WEAK!" or "⚡ DIG NODE!"
	local btnColor = isTooWeak and Color3.fromRGB(231, 76, 60) or Color3.fromRGB(46, 204, 113)
	local btnTextColor = Color3.fromRGB(255, 255, 255)

	return Roact.createElement("ScreenGui", {
		ResetOnSpawn = false,
	}, {
		MainFrame = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.85),
			Position = UDim2.fromScale(0.5, 0.85),
			Size = UDim2.fromOffset(360, 185),
			BackgroundColor3 = Color3.fromRGB(18, 22, 30),
			BorderSizePixel = 0,
		}, {
			UICorner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 14) }),
			UIStroke = Roact.createElement("UIStroke", {
				Color = isTooWeak and Color3.fromRGB(231, 76, 60) or activeColor,
				Thickness = 2,
			}),

			-- Title Banner & Rarity Tag
			HeaderFrame = Roact.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, 36),
				BackgroundTransparency = 1,
			}, {
				RarityBadge = Roact.createElement("TextLabel", {
					Position = UDim2.fromOffset(15, 8),
					Size = UDim2.new(1, -65, 0, 24),
					BackgroundTransparency = 1,
					Text = string.format("%s • %s", string.upper(rarity), itemName),
					TextColor3 = activeColor,
					TextSize = 15,
					Font = Enum.Font.GothamBlack,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),

				-- Tombol Cancel / Close (✕)
				CloseButton = Roact.createElement("TextButton", {
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, -8, 0, 8),
					Size = UDim2.fromOffset(26, 26),
					BackgroundColor3 = Color3.fromRGB(231, 76, 60),
					Text = "✕",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 14,
					Font = Enum.Font.GothamBlack,

					[Roact.Event.Activated] = function()
						if onCancel then
							onCancel()
						end
					end,
				}, {
					UICorner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 13) }),
				}),
			}),

			-- Shovel Power vs Required Weight Info
			PowerRequirementLabel = Roact.createElement("TextLabel", {
				Position = UDim2.fromOffset(15, 38),
				Size = UDim2.new(1, -30, 0, 18),
				BackgroundTransparency = 1,
				Text = string.format("⚡ Power Req: %d (Your Shovel: %d)", minPower, shovelPower),
				TextColor3 = isTooWeak and Color3.fromRGB(231, 76, 60) or Color3.fromRGB(200, 210, 225),
				TextSize = 11,
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),

			-- HP Resistance Bar
			HpBarBackground = Roact.createElement("Frame", {
				Position = UDim2.fromOffset(15, 62),
				Size = UDim2.new(1, -30, 0, 22),
				BackgroundColor3 = Color3.fromRGB(12, 15, 22),
			}, {
				UICorner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
				HpFill = Roact.createElement("Frame", {
					Size = UDim2.fromScale(hpPercent, 1),
					BackgroundColor3 = isTooWeak and Color3.fromRGB(231, 76, 60) or activeColor,
				}, {
					UICorner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
				}),
				HpText = Roact.createElement("TextLabel", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = string.format("HP: %d / %d", currentHp, maxHp),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 11,
					Font = Enum.Font.GothamBold,
				}),
			}),

			-- Warning Text & Live Hitung Mundur (Countdown Timer)
			WarningLabel = Roact.createElement("TextLabel", {
				Position = UDim2.fromOffset(15, 90),
				Size = UDim2.new(1, -30, 0, 16),
				BackgroundTransparency = 1,
				Text = isTooWeak and "⚠️ Upgrade shovel at shop to dig this heavy item!" or string.format("⏱️ Time Remaining: %ds", timeRemaining),
				TextColor3 = isTooWeak and Color3.fromRGB(231, 76, 60) or Color3.fromRGB(241, 196, 15),
				TextSize = 11,
				Font = Enum.Font.GothamBold,
			}),

			-- Tombol Gali / Swing Shovel
			SwingButton = Roact.createElement("TextButton", {
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -12),
				Size = UDim2.new(1, -30, 0, 42),
				BackgroundColor3 = btnColor,
				Text = btnText,
				TextColor3 = btnTextColor,
				TextSize = 15,
				Font = Enum.Font.GothamBlack,
				AutoButtonColor = not isTooWeak,

				[Roact.Event.Activated] = function()
					if not isTooWeak and onSwing then
						onSwing()
					end
				end,
			}, {
				UICorner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 10) }),
			}),
		}),
	})
end

return DigMinigame
