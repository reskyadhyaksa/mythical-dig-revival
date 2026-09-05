--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local packagesFolder = ReplicatedStorage:WaitForChild("Packages")
local Roact = require(packagesFolder:WaitForChild("Roact"))

local clientFolder = script.Parent.Parent
local componentsFolder = clientFolder:WaitForChild("Components")
local HoldPowerBarGui = require(componentsFolder:WaitForChild("HoldPowerBarGui"))

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local commonFolder = sharedFolder:WaitForChild("Common")
local PowerBarHelper = require(commonFolder:WaitForChild("PowerBarHelper")) :: any

local HoldPowerController = {}
HoldPowerController.SWEEP_SPEED = 0.375 -- Kecepatan osilasi bar (detik dari 0% ke 100%)
HoldPowerController.HOLD_WALK_SPEED = 6 -- Kecepatan jalan karakter saat menahan power (Default normal: 16)

function HoldPowerController.SetSweepSpeed(speedSeconds: number)
	HoldPowerController.SWEEP_SPEED = math.max(0.1, speedSeconds)
end

function HoldPowerController.SetHoldWalkSpeed(walkSpeed: number)
	HoldPowerController.HOLD_WALK_SPEED = math.max(0, walkSpeed)
end

local function ApplySlowMovement()
	local localPlayer = Players.LocalPlayer
	local char = localPlayer and localPlayer.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = HoldPowerController.HOLD_WALK_SPEED
	end
end

local function RestoreMovement()
	local localPlayer = Players.LocalPlayer
	local char = localPlayer and localPlayer.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16
	end
end

local currentHandle: any = nil
local isHolding = false
local chargeStartTime = 0
local chargeRenderConnection: RBXScriptConnection? = nil
local onReleaseAction: ((multiplier: number) -> ())? = nil

function HoldPowerController.MountHoldBar()
	if currentHandle then
		return
	end

	local localPlayer = Players.LocalPlayer
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local element = Roact.createElement(HoldPowerBarGui, {
		Visible = false,
		Progress = 0,
		Multiplier = 1.0,
	})

	currentHandle = Roact.mount(element, playerGui, "HoldPowerBarUI")
end

function HoldPowerController.Update(progress: number, multiplier: number, visible: boolean)
	if not currentHandle then
		HoldPowerController.MountHoldBar()
	end

	local element = Roact.createElement(HoldPowerBarGui, {
		Visible = visible,
		Progress = progress,
		Multiplier = multiplier,
	})

	Roact.update(currentHandle, element)
end

-- Menghitung progress osilasi naik-turun halus (0% -> 100% -> 0%...)
function HoldPowerController.CalculateOscillatingProgress(elapsed: number): number
	local speed = HoldPowerController.SWEEP_SPEED
	local cycle = (elapsed / speed) % 2.0
	if cycle <= 1.0 then
		return cycle
	else
		return 2.0 - cycle
	end
end

function HoldPowerController.IsHolding(): boolean
	return isHolding
end

function HoldPowerController.StartHold(onReleaseCallback: ((multiplier: number) -> ())?)
	if isHolding then
		return
	end

	isHolding = true
	chargeStartTime = os.clock()
	onReleaseAction = onReleaseCallback

	ApplySlowMovement()
	HoldPowerController.Update(0, 1.0, true)

	if chargeRenderConnection then
		chargeRenderConnection:Disconnect()
		chargeRenderConnection = nil
	end

	chargeRenderConnection = RunService.RenderStepped:Connect(function()
		if not isHolding then
			return
		end
		local elapsed = os.clock() - chargeStartTime
		local progress = HoldPowerController.CalculateOscillatingProgress(elapsed)
		local multiplier = 1.0 + (progress * 1.5) -- Rentang 1.0X sampai 2.5X
		HoldPowerController.Update(progress, multiplier, true)
	end)
end

function HoldPowerController.ReleaseHold()
	if not isHolding then
		return
	end
	isHolding = false

	if chargeRenderConnection then
		chargeRenderConnection:Disconnect()
		chargeRenderConnection = nil
	end

	RestoreMovement()

	local elapsed = os.clock() - chargeStartTime
	local progress = HoldPowerController.CalculateOscillatingProgress(elapsed)
	local tier = PowerBarHelper.GetLuckTier(progress)

	-- Sembunyikan bar
	HoldPowerController.Update(0, 1.0, false)

	local isDiggable = true
	local DigController: any = nil
	pcall(function()
		DigController = require(clientFolder:WaitForChild("Controllers"):WaitForChild("DigController")) :: any
		if DigController and DigController.IsGroundDiggable then
			isDiggable = DigController.IsGroundDiggable()
		end
	end)

	if not isDiggable then
		if DigController and DigController.ShowInvalidGroundNotice then
			DigController.ShowInvalidGroundNotice("⚠️ Cannot dig here! Invalid ground material.")
		end
		onReleaseAction = nil
		return
	end

	-- Tampilkan pop-up melayang di atas kepala karakter hanya jika tanah valid untuk digali
	local localPlayer = Players.LocalPlayer
	if localPlayer and localPlayer.Character and progress >= 0.20 then
		HoldPowerController.ShowLuckPopup(localPlayer.Character, tier.Name .. "!", tier.Color)
	end

	-- Jalankan callback rilis
	if onReleaseAction then
		local callback = onReleaseAction
		onReleaseAction = nil
		callback(tier.Multiplier)
	end
end

function HoldPowerController.CancelHold()
	if not isHolding then
		return
	end
	isHolding = false
	onReleaseAction = nil

	if chargeRenderConnection then
		chargeRenderConnection:Disconnect()
		chargeRenderConnection = nil
	end

	RestoreMovement()
	HoldPowerController.Update(0, 1.0, false)
end

function HoldPowerController.ShowLuckPopup(character: Model?, tierText: string, tierColor: Color3)
	if not character then
		return
	end

	local head = character:FindFirstChild("Head") :: BasePart?
	if not head then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "LuckTierPopup"
	billboard.Adornee = head
	billboard.Size = UDim2.new(4.5, 0, 1.4, 0)
	billboard.StudsOffset = Vector3.new(0, 4.0, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(0.3, 0.3)
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.BackgroundTransparency = 1
	label.Text = tierText
	label.TextColor3 = tierColor
	label.Font = Enum.Font.LuckiestGuy
	label.TextScaled = true
	label.Parent = billboard

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Thickness = 3
	stroke.Parent = label

	billboard.Parent = head

	local popTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local popTween = TweenService:Create(label, popTweenInfo, {
		Size = UDim2.fromScale(1.0, 1.0),
	})
	popTween:Play()

	task.spawn(function()
		task.wait(0.4)
		local floatTweenInfo = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local floatTween = TweenService:Create(billboard, floatTweenInfo, {
			StudsOffset = Vector3.new(0, 5.6, 0),
		})
		local fadeTween = TweenService:Create(label, floatTweenInfo, {
			TextTransparency = 1,
		})
		local strokeFade = TweenService:Create(stroke, floatTweenInfo, {
			Transparency = 1,
		})

		floatTween:Play()
		fadeTween:Play()
		strokeFade:Play()

		task.wait(0.7)
		billboard:Destroy()
	end)
end

return HoldPowerController
