local ROOT = {}

local Reactor = {}
Reactor.__index = Reactor

function Reactor.new(fabric)
	return setmetatable({
		fabric = fabric;
		_componentStack = {};
		_effectStack = {};
	}, Reactor)
end

function Reactor:push(component, effectKey)
	table.insert(self._componentStack, component)
	table.insert(self._effectStack, effectKey)
end

function Reactor:pop()
	table.remove(self._effectStack, #self._effectStack)
	table.remove(self._componentStack, #self._componentStack)
end

function Reactor:peek()
	return self._componentStack[#self._componentStack], self._effectStack[#self._effectStack]
end

function Reactor._getCallback(component, interestedComponent)
	return function()
		local data = component.data
		local lastData = component.lastData

		for interestedEffectKey, interestedKeys in pairs(interestedComponent._reactsTo[component]) do
			local needsUpdate = false

			for interestedKey in pairs(interestedKeys) do
				if
					interestedKey == ROOT
					or data == nil
					or lastData == nil
					or data[interestedKey] ~= lastData[interestedKey]
				then
					interestedComponent.fabric:debug(
						"[Reactor Push]",
						component,
						interestedKey == ROOT and "root" or interestedKey,
						"->",
						interestedComponent
					)
					needsUpdate = true
					break
				end
			end

			if needsUpdate then
				interestedComponent:_runEffect(interestedEffectKey)
			end
		end
	end
end

function Reactor:react(component, key)
	if component:isDestroyed() then
		-- component:get can still be called if the component is destroyed.
		return
	end

	local interestedComponent, interestedEffectKey = self:peek()

	if interestedComponent == nil then
		return
	end

	assert(key == nil or type(key) == "string", "Effects API does not work with nested keys yet")

	if key == nil then
		key = ROOT
	end

	if interestedComponent._reactsTo[component] == nil then
		self.fabric:debug("[Reactor Interest]", component, "->", interestedComponent)

		interestedComponent._reactsTo[component] = {}

		local cleanupCallback = component:on("updated", self._getCallback(component, interestedComponent))
		interestedComponent:on("destroy", cleanupCallback)
		interestedComponent:on("hotReloaded", cleanupCallback)
		interestedComponent:on("hotReloaded", function()
			interestedComponent._reactsTo[component] = nil
		end)
	end

	if interestedComponent._reactsTo[component][interestedEffectKey] == nil then
		interestedComponent._reactsTo[component][interestedEffectKey] = {}
	end

	interestedComponent._reactsTo[component][interestedEffectKey][key] = true
end

return Reactor