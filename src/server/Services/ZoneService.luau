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

	-- Dukung nama folder "Zone" (dari screenshot) maupun "Zones"
	local zonesFolder = Workspace:FindFirstChild("Zone") or Workspace:FindFirstChild("Zones")
	if not zonesFolder then
		return "Island1"
	end

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = { zonesFolder }

	local touchingParts = Workspace:GetPartsInPart(hrp, overlapParams)

	for _, zonePart in touchingParts do
		-- Jika zonePart ada di dalam folder pulau (misal: Workspace.Zone.Island1.Part)
		if zonePart.Parent and zonePart.Parent ~= zonesFolder and zonePart.Parent.Name ~= "Workspace" then
			return zonePart.Parent.Name -- Mengembalikan "Island1", "Island2", dst.
		end
		return zonePart.Name
	end

	return "Island1"
end

-- Daftar Material Tanah yang Diizinkan untuk Menggali (Sangat mudah ditambah di masa depan!)
ZoneService.AllowedMaterials = {
	Grass = true,
	Sand = true,
	Slate = true,
}

function ZoneService.IsAllowedMaterial(materialName: string): boolean
	return ZoneService.AllowedMaterials[materialName] == true
end

function ZoneService.GetPlayerGroundMaterial(player: Player): string?
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
		if ZoneService.IsAllowedMaterial(matName) then
			return matName
		end
	end

	return nil
end

return ZoneService
