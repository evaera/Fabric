local ROOT = {}

local Reactor = {}
Reactor.__index = Reactor

function Reactor.new(fabric)
	return setmetatable({
		fabric = fabric;
		_unitStack = {};
		_effectStack = {};
	}, Reactor)
end

function Reactor:push(unit, effectKey)
	table.insert(self._unitStack, unit)
	table.insert(self._effectStack, effectKey)
end

function Reactor:pop()
	table.remove(self._effectStack, #self._effectStack)
	table.remove(self._unitStack, #self._unitStack)
end

function Reactor:peek()
	return self._unitStack[#self._unitStack], self._effectStack[#self._effectStack]
end

function Reactor._getCallback(unit, interestedUnit)
	return function(data, lastData)
		for interestedEffectKey, interestedKeys in pairs(interestedUnit._reactsTo[unit]) do
			local needsUpdate = false

			for interestedKey in pairs(interestedKeys) do
				if
					interestedKey == ROOT
					or data == nil
					or lastData == nil
					or data[interestedKey] ~= lastData[interestedKey]
				then
					interestedUnit.fabric:debug(
						"[Reactor Push]",
						unit,
						interestedKey == ROOT and "root" or interestedKey,
						"->",
						interestedUnit
					)
					needsUpdate = true
					break
				end
			end

			if needsUpdate then
				interestedUnit:_runEffect(interestedEffectKey)
			end
		end
	end
end

function Reactor:react(unit, key)
	if unit:isDestroyed() then
		-- unit:get can still be called if the unit is destroyed.
		return
	end

	local interestedUnit, interestedEffectKey = self:peek()

	if interestedUnit == nil then
		return
	end

	assert(key == nil or type(key) == "string", "Effects API does not work with nested keys yet")

	if key == nil then
		key = ROOT
	end

	if interestedUnit._reactsTo[unit] == nil then
		self.fabric:debug("[Reactor Interest]", unit, "->", interestedUnit)

		interestedUnit._reactsTo[unit] = {}

		local cleanupCallback = unit:on("updated", self._getCallback(unit, interestedUnit))
		interestedUnit:on("destroy", cleanupCallback)
		interestedUnit:on("hotReloaded", cleanupCallback)
		interestedUnit:on("hotReloaded", function()
			interestedUnit._reactsTo[unit] = nil
		end)
	end

	if interestedUnit._reactsTo[unit][interestedEffectKey] == nil then
		interestedUnit._reactsTo[unit][interestedEffectKey] = {}
	end

	interestedUnit._reactsTo[unit][interestedEffectKey][key] = true
end

return Reactor