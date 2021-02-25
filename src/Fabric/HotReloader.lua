local HotReloader = {}
HotReloader.__index = HotReloader

function HotReloader.new(fabric)
	return setmetatable({
		fabric = fabric;
		staticUnits = {};
	}, HotReloader)
end

function HotReloader:giveModule(module, initialValue)
	self.staticUnits[module] = initialValue

	module.Changed:Connect(function()
		local newStaticUnit = require(module:Clone())
		local oldStaticUnit = self.staticUnits[module]

		if newStaticUnit.name == nil then
			newStaticUnit.name = module.Name
		end

		self.fabric._collection:register(newStaticUnit, true)
		self.fabric:fire("unitHotReloaded", newStaticUnit)

		local count = 0
		for _, unitMap in pairs(self.fabric._collection._refUnits) do
			if unitMap[oldStaticUnit] then
				unitMap[newStaticUnit] = unitMap[oldStaticUnit]
				unitMap[oldStaticUnit] = nil

				setmetatable(unitMap[newStaticUnit], newStaticUnit)
				unitMap[newStaticUnit]:fire("hotReloaded")

				local ok, errorValue = xpcall(function()
					unitMap[newStaticUnit]:_runEffects()
				end, function(innerErrorValue)
					return debug.traceback(innerErrorValue)
				end)

				if not ok then
					warn(("Effects of %s encountered an error during hot reloading:\n\n%s"):format(
						tostring(unitMap[newStaticUnit]),
						tostring(errorValue)
					))
				end

				count += 1
			end
		end

		self.staticUnits[module] = newStaticUnit

		self.fabric:debug("[Hot Reload]", module.Name, "->", count, "units")
	end)
end

return HotReloader
