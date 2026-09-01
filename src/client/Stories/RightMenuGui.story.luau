--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Roact = require(Packages.Roact)
local RightMenuGui = require(script.Parent.Parent.Components.RightMenuGui)

return function(target: Instance)
	local handle = Roact.mount(Roact.createElement(RightMenuGui, {
		OnOpenInventory = function()
			print("Storybook: Inventory Opened")
		end,
		OnOpenShop = function()
			print("Storybook: Shop Opened")
		end,
	}), target)

	return function()
		Roact.unmount(handle)
	end
end
