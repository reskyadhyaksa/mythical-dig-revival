--!strict
local NameplateService = {}

local MAX_VIEW_DISTANCE_STUDS = 35

function NameplateService.CreateNameplate(player: Player, character: Model, level: number)
	task.spawn(function()
		local head = character:WaitForChild("Head", 5) :: BasePart?
		local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?

		if humanoid then
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		end

		if not head then
			return
		end

		local existing = head:FindFirstChild("OverheadNameplate") or character:FindFirstChild("OverheadNameplate")
		if existing then
			existing:Destroy()
		end

		local billboard = Instance.new("BillboardGui")
		billboard.Name = "OverheadNameplate"
		billboard.Adornee = head
		billboard.Size = UDim2.new(4.2, 0, 1.25, 0)
		billboard.StudsOffset = Vector3.new(0, 2.6, 0)
		billboard.MaxDistance = MAX_VIEW_DISTANCE_STUDS
		billboard.AlwaysOnTop = true
		billboard.LightInfluence = 0

		local container = Instance.new("Frame")
		container.Name = "Container"
		container.Size = UDim2.fromScale(1, 1)
		container.BackgroundTransparency = 1
		container.BorderSizePixel = 0
		container.Parent = billboard

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Position = UDim2.fromScale(0, 0.08)
		nameLabel.Size = UDim2.fromScale(1, 0.48)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = player.DisplayName
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.Font = Enum.Font.GothamBlack
		nameLabel.TextStrokeColor3 = Color3.fromHex("00426D")
		nameLabel.TextStrokeTransparency = 0
		nameLabel.TextSize = 14
		nameLabel.TextScaled = true

		local nameStroke = Instance.new("UIStroke")
		nameStroke.Color = Color3.fromHex("00426D")
		nameStroke.Thickness = 1.5
		nameStroke.Parent = nameLabel

		nameLabel.Parent = container

		local levelLabel = Instance.new("TextLabel")
		levelLabel.Name = "LevelLabel"
		levelLabel.Position = UDim2.fromScale(0, 0.54)
		levelLabel.Size = UDim2.fromScale(1, 0.25)
		levelLabel.BackgroundTransparency = 1
		levelLabel.Text = string.format("Lvl: %d", level)
		levelLabel.TextColor3 = Color3.fromRGB(202, 148, 0)
		levelLabel.Font = Enum.Font.GothamBold
		levelLabel.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
		levelLabel.TextStrokeTransparency = 0
		levelLabel.TextSize = 12
		levelLabel.TextScaled = true

		levelLabel.Parent = container

		billboard.Parent = head
		print(
			string.format("🏷️ Created overhead nameplate for %s (Level %d | MaxDistance: 20m)", player.Name, level)
		)
	end)
end

function NameplateService.UpdateLevel(character: Model?, newLevel: number)
	if not character then
		return
	end
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end
	local billboard = head:FindFirstChild("OverheadNameplate")
	if not billboard then
		return
	end
	local container = billboard:FindFirstChild("Container")
	if not container then
		return
	end
	local levelLabel = container:FindFirstChild("LevelLabel") :: TextLabel?
	if levelLabel then
		levelLabel.Text = string.format("Level %d", newLevel)
		print(string.format("🏷️ Updated overhead level to %d for %s", newLevel, character.Name))
	end
end

return NameplateService
