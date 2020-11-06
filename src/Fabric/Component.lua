local Comparators = require(script.Parent.Operators.Comparators)
local Reducers = require(script.Parent.Operators.Reducers)
local Symbol = require(script.Parent.Parent.Shared.Symbol)
local Util = require(script.Parent.Parent.Shared.Util)

local RESERVED_SCOPES = {
	[Symbol.named("base")] = true;
	[Symbol.named("remote")] = true;
}

local Component = {}
Component.__index = Component

function Component:fire(eventName, ...)
	if not self._listeners then
		error(("Cannot fire event %q because this component is destroyed."):format(
			tostring(eventName)
		))
	end

	-- call a method of the event name if it exists
	local methodName = "on" .. eventName:sub(1, 1):upper() .. eventName:sub(2)
	if self[methodName] then
		local thread = coroutine.create(self[methodName])

		local success, errorValue = coroutine.resume(thread, self, ...)

		if not success then
			warn(("%q method of %s encounetered an error: %s"):format(
				tostring(methodName),
				tostring(self),
				tostring(errorValue)
			))

			return
		end

		if coroutine.status(thread) ~= "dead" then
			warn(("Yielding in %s of %s is not allowed!"):format(
				tostring(methodName),
				tostring(self)
			))
		end
	end

	if not self._listeners[eventName] then
		return -- Do nothing if no listeners registered
	end

	for _, callback in ipairs(self._listeners[eventName]) do
		local success, errorValue = coroutine.resume(coroutine.create(callback), ...)

		if not success then
			warn(("Event listener of %s for %q encountered an error: %s"):format(
				tostring(self),
				tostring(eventName),
				tostring(errorValue)
			))
		end
	end
end

function Component:on(eventName, callback)
	if not self._listeners then
		error(("Cannot attach event listener %q because this component is destroyed."):format(
			tostring(eventName)
		))
	end

	self._listeners[eventName] = self._listeners[eventName] or {}
	table.insert(self._listeners[eventName], callback)

	return function()
		if self._listeners == nil then
			-- This component has been destroyed
			return
		end

		for i, listCallback in ipairs(self._listeners[eventName]) do
			if listCallback == callback then
				table.remove(self._listeners[eventName], i)
				break
			end
		end
	end
end

function Component:get(key)
	self.fabric._reactor:react(self, key)

	local object = self.data

	if object == nil then
		return
	end

	if key == nil then
		return object
	end

	if type(key) == "table" then
		for _, field in ipairs(key) do
			object = object[field]

			if object == nil then
				return
			end
		end

		return object
	else
		return object[key]
	end
end

function Component:getComponent(componentResolvable)
	return self.fabric._collection:getComponentByRef(componentResolvable, self)
end

function Component:getOrCreateComponent(componentResolvable)
	return self.fabric._collection:getOrCreateComponentByRef(componentResolvable, self)
end

function Component:isDestroyed()
	return self._destroyed or false
end

function Component:addLayer(scope, data)
	return self:_addLayer(scope, data)
end

function Component:mergeWithBaseLayer(data)
	local baseLayer = self._layers[Symbol.named("base")]
	-- create new data for layer --
	local newBaseLayer = {}
	for _, tbl in ipairs({baseLayer, data}) do
		for key, value in pairs(tbl) do
			newBaseLayer[key] = value
		end
	end
	return self:setBaseLayer(newBaseLayer)
end

function Component:removeLayer(scope)
	return self:_removeLayer(scope)
end

function Component:_addLayer(scope, data)
	if data == nil then
		return self:_removeLayer(scope)
	end

	self._layers[scope] = data

	self:_changed()
end

function Component:_removeLayer(scope)
	self._layers[scope] = nil
	self:_changed()

	local shouldDestroy = next(self._layers) == nil

	if shouldDestroy then
		self:fire("destroy")
	end
end

function Component:_runEffect(key)
	self.fabric._reactor:push(self, key)

	local thread = coroutine.create(self.effects[key])
	local success, errorValue = coroutine.resume(thread, self)

	if coroutine.status(thread) ~= "dead" then
		warn(("Effect %q of %s yielded! This is very illegal."):format(
			tostring(key),
			tostring(self)
		))
	end

	self.fabric._reactor:pop()

	if not success then
		warn(("Effect %q of %s encountered an error: %s"):format(
			tostring(key),
			tostring(self),
			tostring(errorValue)
		))
	end
end

function Component:_runEffects()
	if self.effects == nil then
		return
	end

	-- Run in order if the keys are numbers
	local iterator = pairs
	if #self.effects > 0 then
		iterator = ipairs
	end

	for key in iterator(self.effects) do
		self:_runEffect(key)
	end
end

function Component:_changed()
	local lastData = self.data
	local newData = self:_reduce()

	self.data = newData
	self.lastData = lastData

	if lastData == nil and newData ~= nil then
		self._loaded = true
		self._loading = false
		self:fire("loaded", newData)

		self:_runEffects()
	end

	if (self.shouldUpdate or Comparators.default)(newData, lastData) then
		self:fire("updated")
	end

	self.lastData = nil
end

function Component:_reduce()
	if next(self._layers) == nil then
		return
	end

	local values = { self._layers[Symbol.named("remote")] }
	table.insert(values, self._layers[Symbol.named("base")])

	for name, data in pairs(self._layers) do
		if RESERVED_SCOPES[name] == nil then
			table.insert(values, data)
		end
	end

	local reducedValue = (self.reducer or Reducers.default)(values)
	local data = reducedValue

	if self.defaults and type(self.defaults) == "table" then
		data = Util.assign({}, self.defaults, reducedValue)
	end

	if self.schema then
		assert(self.schema(data))
	end

	return data
end

function Component:isLoaded()
	return self._loaded
end

function Component:setIsLoading()
	if self._loaded then
		error("Attempt to call setIsLoading when this component is already loaded.")
	end

	self._loading = true
end

function Component:__tostring()
	return ("Component(%s)"):format(
		typeof(self.ref) == "Instance" and ("%s, %s"):format(self.name, self.ref.Name) or self.name
	)
end

return Component