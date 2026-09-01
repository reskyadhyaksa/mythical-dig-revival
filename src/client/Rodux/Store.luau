--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rodux = require(ReplicatedStorage.Packages.Rodux)

local Reducers = require(script.Parent.Reducers)

local Store = Rodux.Store.new(Reducers, nil, {
	Rodux.thunkMiddleware,
})

return Store
