--!strict
export type IslandWaypointDef = {
	Id: string,
	Name: string,
	WorldPosition: Vector3,
}

local IslandWaypoints: { [string]: IslandWaypointDef } = {
	["Island1"] = {
		Id = "Island1",
		Name = "Echoes",
		WorldPosition = Vector3.new(100, 100, -85),
	},
	["Island2"] = {
		Id = "Island2",
		Name = "Dragon Altar",
		WorldPosition = Vector3.new(350, 4.056, -120),
	},
}

local IslandWaypointsModule = {}
IslandWaypointsModule.Dict = IslandWaypoints

function IslandWaypointsModule.GetWaypoints(): { [string]: IslandWaypointDef }
	return IslandWaypoints
end

function IslandWaypointsModule.GetWaypoint(islandId: string): IslandWaypointDef?
	return IslandWaypoints[islandId]
end

return IslandWaypointsModule
