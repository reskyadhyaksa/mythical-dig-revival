--!strict
local Workspace = game:GetService("Workspace")

local ZoneService = {}

function ZoneService.GetPlayerIsland(player: Player): string
	local character = player.Character
	if not character then
		return "Island1"
	end

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return "Island1"
	end

	local zonesFolder = Workspace:FindFirstChild("Zone") or Workspace:FindFirstChild("Zones")
	if not zonesFolder then
		return "Island1"
	end

	local hrpPos = hrp.Position

	-- 1. Deteksi presisi 3D Spatial Box: periksa part 'Border' di setiap folder pulau (contoh: Workspace.Zone.Island1.Border)
	for _, islandFolder in zonesFolder:GetChildren() do
		local borderPart = islandFolder:FindFirstChild("Border", true) :: BasePart?
		if borderPart and borderPart:IsA("BasePart") then
			local relativePos = borderPart.CFrame:PointToObjectSpace(hrpPos)
			local halfSize = borderPart.Size / 2

			-- Mengecek apakah posisi player berada di dalam volume area kubus Border
			if math.abs(relativePos.X) <= halfSize.X and math.abs(relativePos.Z) <= halfSize.Z then
				if math.abs(relativePos.Y) <= math.max(halfSize.Y, 500) then
					return islandFolder.Name -- Mengembalikan "Island1", "Island2", dst.
				end
			end
		end
	end

	-- 2. Deteksi cadangan: jika ada part langsung yang dinamai Border atau nama pulau
	for _, islandChild in zonesFolder:GetChildren() do
		if islandChild:IsA("BasePart") then
			local relativePos = islandChild.CFrame:PointToObjectSpace(hrpPos)
			local halfSize = islandChild.Size / 2
			if math.abs(relativePos.X) <= halfSize.X
				and math.abs(relativePos.Y) <= halfSize.Y
				and math.abs(relativePos.Z) <= halfSize.Z
			then
				return islandChild.Name
			end
		end
	end

	return "Island1"
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local ItemHelper = require(sharedFolder:WaitForChild("Common"):WaitForChild("ItemHelper")) :: any

-- Daftar Material Tanah Global (Fallback)
ZoneService.AllowedMaterials = {
	Grass = true,
	Sand = true,
	Slate = true,
}

function ZoneService.IsAllowedMaterial(materialName: string, islandId: string?): boolean
	if islandId then
		local islandMats = ItemHelper.GetIslandMaterials(islandId)
		if islandMats and table.find(islandMats, materialName) then
			return true
		end
	end
	return ZoneService.AllowedMaterials[materialName] == true
end

function ZoneService.GetPlayerGroundMaterial(player: Player, islandId: string?): string?
	local character = player.Character
	if not character then
		return nil
	end

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return nil
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { character }

	local result = Workspace:Raycast(hrp.Position, Vector3.new(0, -15, 0), raycastParams)
	if result and result.Material then
		local matName = result.Material.Name
		local currentIsland = islandId or ZoneService.GetPlayerIsland(player)
		if ZoneService.IsAllowedMaterial(matName, currentIsland) then
			return matName
		end
	end

	return nil
end

return ZoneService
