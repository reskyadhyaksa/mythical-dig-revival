--!strict
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local packagesFolder = ReplicatedStorage:WaitForChild("Packages")
local Roact = require(packagesFolder:WaitForChild("Roact"))

local clientFolder = script.Parent.Parent
local componentsFolder = clientFolder:WaitForChild("Components")
local DigMinigame = require(componentsFolder:WaitForChild("DigMinigame"))

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local startDigRF = remotesFolder:WaitForChild("StartDig") :: RemoteFunction
local swingShovelRF = remotesFolder:WaitForChild("SwingShovel") :: RemoteFunction
local cancelDigRE = remotesFolder:WaitForChild("CancelDig") :: RemoteEvent

local toolControllerRef: any = nil
local function getToolController()
	if not toolControllerRef then
		local Controllers = clientFolder:WaitForChild("Controllers")
		toolControllerRef = require(Controllers:WaitForChild("ToolController")) :: any
	end
	return toolControllerRef
end

local DigController = {}
local currentHandle: any = nil
local isDigMinigameActive = false
local isPreparingDig = false
local activeInputConnection: RBXScriptConnection? = nil
local onSwingExternalAction: (() -> ())? = nil

function DigController.IsGroundDiggable(): boolean
	local localPlayer = Players.LocalPlayer
	local character = localPlayer and localPlayer.Character
	if not character then
		return false
	end

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return false
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { character }

	local result = Workspace:Raycast(hrp.Position, Vector3.new(0, -15, 0), raycastParams)
	if not result or not result.Material then
		return false
	end

	local matName = result.Material.Name
	if matName == "Grass" or matName == "Sand" or matName == "Slate" then
		return true
	end

	local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
	local itemsModule = sharedFolder
		and sharedFolder:FindFirstChild("Data")
		and sharedFolder.Data:FindFirstChild("Items")
	if itemsModule then
		local Items = require(itemsModule) :: any
		if Items and Items.IslandMaterials then
			for _, mats in pairs(Items.IslandMaterials) do
				if table.find(mats, matName) then
					return true
				end
			end
		end
	end

	return false
end

local currentNoticeGui: ScreenGui? = nil

function DigController.ShowInvalidGroundNotice(customMessage: string?)
	local localPlayer = Players.LocalPlayer
	local playerGui = localPlayer and localPlayer:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return
	end

	-- Hapus notice sebelumnya jika masih aktif agar tidak tumpang tindih
	if currentNoticeGui then
		currentNoticeGui:Destroy()
		currentNoticeGui = nil
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "NoticeNotificationUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 100
	currentNoticeGui = screenGui

	local frame = Instance.new("Frame")
	frame.Name = "NoticeFrame"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.40)
	frame.Size = UDim2.fromOffset(360, 50)
	frame.BackgroundColor3 = Color3.fromRGB(25, 20, 25)
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(235, 75, 75) -- Alert Red
	stroke.Thickness = 2
	stroke.Parent = frame

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "NoticeText"
	textLabel.Size = UDim2.new(1, -20, 1, 0)
	textLabel.Position = UDim2.new(0, 10, 0, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = customMessage or "⚠️ Cannot dig here! Invalid ground material."
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextSize = 15
	textLabel.TextXAlignment = Enum.TextXAlignment.Center
	textLabel.TextYAlignment = Enum.TextYAlignment.Center
	textLabel.Parent = frame

	screenGui.Parent = playerGui

	-- Animasi Pop-In
	frame.Size = UDim2.fromOffset(260, 36)
	frame.Position = UDim2.fromScale(0.5, 0.43)
	frame.BackgroundTransparency = 1
	textLabel.TextTransparency = 1
	stroke.Transparency = 1

	local popTween = TweenService:Create(frame, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(360, 50),
		Position = UDim2.fromScale(0.5, 0.40),
		BackgroundTransparency = 0.15,
	})
	local textPopTween =
		TweenService:Create(textLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = 0,
		})
	local strokePopTween =
		TweenService:Create(stroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Transparency = 0,
		})

	popTween:Play()
	textPopTween:Play()
	strokePopTween:Play()

	-- Fade Out setelah 1.6 detik
	task.spawn(function()
		task.wait(1.6)
		if screenGui == currentNoticeGui and screenGui.Parent then
			local fadeInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local fadeFrame = TweenService:Create(frame, fadeInfo, {
				Position = UDim2.fromScale(0.5, 0.36),
				BackgroundTransparency = 1,
			})
			local fadeText = TweenService:Create(textLabel, fadeInfo, {
				TextTransparency = 1,
			})
			local fadeStroke = TweenService:Create(stroke, fadeInfo, {
				Transparency = 1,
			})

			fadeFrame:Play()
			fadeText:Play()
			fadeStroke:Play()

			task.wait(0.35)
			if screenGui == currentNoticeGui then
				screenGui:Destroy()
				currentNoticeGui = nil
			end
		end
	end)
end

local function ShowRarityExclamation(character: Model, rarity: string, duration: number?)
	local head = character:FindFirstChild("Head") :: BasePart?
	if not head then
		return
	end

	local displayDuration = duration or 0.7

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "RarityExclamationPopup"
	billboard.Adornee = head
	billboard.Size = UDim2.new(3.0, 0, 3.0, 0)
	billboard.StudsOffset = Vector3.new(0, 3.8, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(0.2, 0.2)
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.BackgroundTransparency = 1
	label.Text = "!"
	label.Font = Enum.Font.LuckiestGuy
	label.TextScaled = true
	label.Parent = billboard

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Thickness = 3.5
	stroke.Parent = label

	local normalizedRarity = rarity:lower()
	if normalizedRarity == "secret" then
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		local gradient = Instance.new("UIGradient")
		-- Linear dari bawah (merah gelap) ke atas (merah terang)
		gradient.Rotation = -90
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(110, 0, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 35, 35)),
		})
		gradient.Parent = label
	elseif normalizedRarity == "legendary" then
		label.TextColor3 = Color3.fromRGB(255, 215, 0) -- Kuning Emas
	elseif normalizedRarity == "epic" then
		label.TextColor3 = Color3.fromRGB(180, 70, 255) -- Ungu
	elseif normalizedRarity == "rare" then
		label.TextColor3 = Color3.fromRGB(80, 180, 255) -- Biru Muda
	elseif normalizedRarity == "uncommon" then
		label.TextColor3 = Color3.fromRGB(120, 255, 120) -- Hijau Muda
	else
		label.TextColor3 = Color3.fromRGB(255, 255, 255) -- Putih (Common)
	end

	billboard.Parent = head

	local popTween = TweenService:Create(label, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(1.0, 1.0),
	})
	popTween:Play()

	task.spawn(function()
		task.wait(displayDuration * 0.45)
		local floatTween = TweenService:Create(
			billboard,
			TweenInfo.new(displayDuration * 0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				StudsOffset = Vector3.new(0, 5.0, 0),
			}
		)
		local fadeTween = TweenService:Create(
			label,
			TweenInfo.new(displayDuration * 0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				TextTransparency = 1,
			}
		)
		local strokeFade = TweenService:Create(
			stroke,
			TweenInfo.new(displayDuration * 0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Transparency = 1,
			}
		)

		floatTween:Play()
		fadeTween:Play()
		strokeFade:Play()

		task.wait(displayDuration * 0.55)
		billboard:Destroy()
	end)
end

function DigController.IsMinigameActive(): boolean
	return isDigMinigameActive or isPreparingDig
end

function DigController.GetSwingAction(): (() -> ())?
	return onSwingExternalAction
end

function DigController.LockPlayerMovement()
	local player = Players.LocalPlayer
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpHeight = 0
		humanoid.JumpPower = 0
	end
end

function DigController.UnlockPlayerMovement()
	local player = Players.LocalPlayer
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16
		humanoid.JumpHeight = 7.2
		humanoid.JumpPower = 50
	end
end

local function CleanupInputConnection()
	if activeInputConnection then
		activeInputConnection:Disconnect()
		activeInputConnection = nil
	end
end

function DigController.UnmountMinigame()
	CleanupInputConnection()
	onSwingExternalAction = nil
	DigController.UnlockPlayerMovement()

	local tc = getToolController()
	if tc and tc.StopMinigameDigLoop then
		tc.StopMinigameDigLoop()
	end

	if currentHandle then
		Roact.unmount(currentHandle)
		currentHandle = nil
	end

	pcall(function()
		local Controllers = clientFolder:WaitForChild("Controllers")
		local MobileDigController = require(Controllers:WaitForChild("MobileDigController")) :: any
		MobileDigController.Update()
	end)
end

function DigController.CancelDig()
	if not isDigMinigameActive then
		return
	end
	CleanupInputConnection()
	cancelDigRE:FireServer()
	DigController.UnmountMinigame()
	task.wait(0.15)
	isDigMinigameActive = false
end

function DigController.MountMinigameUI(digData: any, isAutoMode: boolean?)
	if not digData then
		return
	end

	CleanupInputConnection()
	isDigMinigameActive = true

	-- Animasi tetap berjalan dan looping sangat lambat saat minigame aktif (idle state)
	local tc = getToolController()
	if tc and tc.StartMinigameDigLoop then
		tc.StartMinigameDigLoop(0.35)
	end

	pcall(function()
		local Controllers = clientFolder:WaitForChild("Controllers")
		local MobileDigController = require(Controllers:WaitForChild("MobileDigController")) :: any
		MobileDigController.Update()
	end)

	local currentHp = digData.CurrentHp
	local maxHp = digData.MaxHp
	local rarity = digData.Rarity
	local itemName = digData.ItemName
	local minDigPower = digData.MinDigPower
	local shovelPower = digData.ShovelPower
	local isTooWeak = digData.IsTooWeak
	local timeLimit = digData.TimeLimit

	local function OnCancelClicked()
		DigController.CancelDig()
	end

	local function OnSwingClicked()
		if isTooWeak then
			return
		end

		local tc = getToolController()
		if tc and tc.PlayDigSwing then
			tc.PlayDigSwing(1)
		elseif tc and tc.PlayDigAnimation then
			tc.PlayDigAnimation()
		end

		local updatedState = swingShovelRF:InvokeServer()
		if updatedState then
			if updatedState.IsFinished then
				CleanupInputConnection()

				-- 1. Tampilkan bar 100% penuh sesaat
				DigController.MountComponent(
					rarity,
					0,
					updatedState.MaxHp or maxHp,
					itemName,
					minDigPower,
					shovelPower,
					isTooWeak,
					timeLimit,
					nil,
					nil,
					isAutoMode
				)

				task.wait(0.4)
				DigController.UnmountMinigame()
				task.wait(0.15)
				isDigMinigameActive = false
			else
				DigController.MountComponent(
					rarity,
					updatedState.CurrentHp,
					updatedState.MaxHp,
					itemName,
					minDigPower,
					shovelPower,
					isTooWeak,
					timeLimit,
					OnSwingClicked,
					OnCancelClicked,
					isAutoMode
				)
			end
		else
			DigController.UnmountMinigame()
			task.wait(0.15)
			isDigMinigameActive = false
		end
	end

	onSwingExternalAction = OnSwingClicked

	-- Bebas Klik di layar untuk mengayun sekop manual tanpa mengganggu tombol GUI lain
	activeInputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			OnSwingClicked()
		end
	end)

	DigController.MountComponent(
		rarity,
		currentHp,
		maxHp,
		itemName,
		minDigPower,
		shovelPower,
		isTooWeak,
		timeLimit,
		OnSwingClicked,
		OnCancelClicked,
		isAutoMode
	)
end

function DigController.MountComponent(
	rarity: string,
	currentHp: number,
	maxHp: number,
	itemName: string?,
	minDigPower: number?,
	shovelPower: number?,
	isTooWeak: boolean?,
	timeLimit: number?,
	onSwingCallback: (() -> ())?,
	onCancelCallback: (() -> ())?,
	isAutoMode: boolean?
)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	if not isAutoMode then
		DigController.LockPlayerMovement()
	else
		DigController.UnlockPlayerMovement()
	end

	local element = Roact.createElement(DigMinigame, {
		Rarity = rarity,
		CurrentHp = currentHp,
		MaxHp = maxHp,
		ItemName = itemName or "Node",
		MinDigPower = minDigPower or 5,
		ShovelPower = shovelPower or 10,
		IsTooWeak = isTooWeak or false,
		TimeLimit = timeLimit or 15,
		OnSwing = onSwingCallback,
		OnCancel = onCancelCallback,
	})

	if currentHandle then
		currentHandle = Roact.update(currentHandle, element)
	else
		currentHandle = Roact.mount(element, playerGui, "DigMinigameUI")
	end
end

function DigController.StartDig(luckMultiplier: number?, isAutoMode: boolean?): boolean
	if isDigMinigameActive or isPreparingDig then
		return false
	end

	-- 1. Cek terlebih dahulu apakah material tanah tempat berdiri diizinkan untuk digali
	if not DigController.IsGroundDiggable() then
		DigController.ShowInvalidGroundNotice("⚠️ Cannot dig here! Invalid ground material.")
		return false
	end

	-- 2. Request data node/item ke server untuk validasi
	local digData = startDigRF:InvokeServer(luckMultiplier)
	if not digData then
		return false
	end

	-- 3. Jika ground valid dan server menyetujui, mulai alur digging aktif
	isPreparingDig = true

	local localPlayer = Players.LocalPlayer
	local character = localPlayer and localPlayer.Character

	if not isAutoMode then
		DigController.LockPlayerMovement()
	end

	local tc = getToolController()
	if tc and tc.PlayDigAnimation then
		tc.PlayDigAnimation()
	end

	local digDuration = 1.0 + (math.random(0, 10) / 10) -- Rentang 1.0s sampai 2.0s random
	local startTime = os.clock()
	local exclamationTriggered = false

	-- Loop penggalian berkelanjutan hingga minigame di-mount tanpa jeda animasi
	while (os.clock() - startTime) < (digDuration + 0.6) do
		-- Pastikan animasi ayunan sekop terus berulang tanpa terputus
		if tc and tc.PlayDigAnimation then
			tc.PlayDigAnimation()
		end

		-- Munculkan tanda seru "!" saat delay digging dasar tercapai, sambil animasi digging TERUS berlanjut
		if not exclamationTriggered and (os.clock() - startTime) >= digDuration then
			exclamationTriggered = true
			if character and digData.Rarity then
				ShowRarityExclamation(character, digData.Rarity, 0.7)
			end
		end

		task.wait(0.05)
	end

	-- 4. Langsung mount minigame UI secara mulus menyatu dengan animasi ayunan
	isPreparingDig = false
	DigController.MountMinigameUI(digData, isAutoMode)
	return true
end

return DigController
