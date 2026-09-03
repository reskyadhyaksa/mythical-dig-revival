--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local packagesFolder = ReplicatedStorage:WaitForChild("Packages")
local Rodux = require(packagesFolder:WaitForChild("Rodux"))

local Reducers = require(script.Parent.Reducers)

local Store = Rodux.Store.new(Reducers, nil, {
	Rodux.thunkMiddleware,
})

return Store
