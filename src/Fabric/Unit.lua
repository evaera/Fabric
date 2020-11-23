local Comparators = require(script.Parent.Operators.Comparators)
local Reducers = require(script.Parent.Operators.Reducers)
local Symbol = require(script.Parent.Parent.Shared.Symbol)
local Util = require(script.Parent.Parent.Shared.Util)

local RESERVED_SCOPES = {
	[Symbol.named("base")] = true;
	[Symbol.named("remote")] = true;
}

local Unit = {}
Unit.__index = Unit

--[=[
	Fires a unit event.

	@param eventName string -- The event name to fire
	@param ... any -- The arguments to fire the event with.
	@return nil
]=]
function Unit:fire(eventName, ...)
	if self:isDestroyed() then
		error(("Cannot fire event %q because this unit is destroyed."):format(
			tostring(eventName)
		))
	end

	-- call a method of the event name if it exists
	local methodName = "on" .. eventName:sub(1, 1):upper() .. eventName:sub(2)
	if self[methodName] then
		debug.profilebegin(("%s: %s"):format(
			tostring(self),
			tostring(methodName)
		))

		local thread = coroutine.create(self[methodName])
		local success, errorValue = coroutine.resume(thread, self, ...)

		debug.profileend()

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

	for i, callback in ipairs(self._listeners[eventName]) do
		debug.profilebegin(("%s: %s (%d)"):format(
			tostring(self),
			tostring(eventName),
			i
		))

		local success, errorValue = coroutine.resume(coroutine.create(callback), ...)

		debug.profileend()

		if not success then
			warn(("Event listener of %s for %q encountered an error: %s"):format(
				tostring(self),
				tostring(eventName),
				tostring(errorValue)
			))
		end
	end
end

--[=[
	Listens to a unit event.

	@param eventName string -- The event name to listen to
	@param callback function -- The callback fired
	@return function -- A function that disconnects the listener when called
]=]
function Unit:on(eventName, callback)
	if self:isDestroyed() then
		error(("Cannot attach event listener %q because this unit is destroyed."):format(
			tostring(eventName)
		))
	end

	self._listeners[eventName] = self._listeners[eventName] or {}
	table.insert(self._listeners[eventName], callback)

	-- The disconnect callback closes on `self`, which will prevent it from being
	-- GC'd as long as a reference to the callback exists. We use a weak values
	-- container to allow the unit to be cleaned up even if a callback
	-- exists.
	local weakSelfContainer = setmetatable({ self = self }, { __mode = "v" })

	return function()
		local weakSelf = weakSelfContainer.self

		if not weakSelf then
			return
		end

		if weakSelf._listeners == nil then
			-- This unit has been destroyed
			return
		end

		for i, listCallback in ipairs(weakSelf._listeners[eventName]) do
			if listCallback == callback then
				table.remove(weakSelf._listeners[eventName], i)
				break
			end
		end
	end
end

--[=[
	Gets the value associated with a key from the unit's data.
	If called from within an effect, then also attach a Reactor interest to it.
	::: warning
	If `:get` is not called on the first run of the effect, then the Reactor interest may not be registered!
	It is highly recommended to do all `:get` calls at the beginning of the effect.
	:::

	@param key string -- The key to get
	@param callback function -- The callback fired
	@return function -- A function that disconnects the listener when called
]=]
function Unit:get(key)
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
	elseif type(object) == "table" then
		return object[key]
	else
		error("Can't call Unit:get() with a parameter when unit data isn't a table")
	end
end

--[=[
	Returns the unit associated with a unit resolvable that is attached to this unit,
	or nil if it doesn't exist.
	Equivalent to calling fabric:getUnitByRef(unitResolvable, unit).

	@param unitResolvable UnitResolvable -- The unit to retrieve
	@return Unit? -- The attached unit
]=]
function Unit:getUnit(unitResolvable)
	self:assertNotDestroyed()
	return self.fabric._collection:getUnitByRef(unitResolvable, self)
end

--[=[
	Returns the unit associated with a unit resolvable that is attached to this unit.
	If it does not exist, then creates and attaches the unit to ref and returns it.
	Equivalent to calling fabric:getOrCreateUnitByRef(unitResolvable, unit).

	@param unitResolvable UnitResolvable -- The unit to retrieve
	@return Unit -- The attached unit
]=]
function Unit:getOrCreateUnit(unitResolvable)
	self:assertNotDestroyed()
	return self.fabric._collection:getOrCreateUnitByRef(unitResolvable, self)
end

--[=[
	Returns true if the unit is destroyed.

	@return bool -- Whether or not the unit is destroyed.
]=]
function Unit:isDestroyed()
	return self._destroyed or false
end

--[=[
	Throws an error if the unit is destroyed.
]=]
function Unit:assertNotDestroyed()
	assert(self:isDestroyed() == false, "This unit is destroyed!")
end

--[=[
	Adds a layer to the unit.

	@param scope string -- The scope to add the layer with
	@param data any -- The layer's data (will overwrite previous data!)
]=]
function Unit:addLayer(scope, data)
	self:assertNotDestroyed()
	return self:_addLayer(scope, data)
end

--[=[
	Merges the data into the base layer.

	@param data table -- The data to merge into the base layer
]=]
function Unit:mergeBaseLayer(data)
	self:assertNotDestroyed()
	local existingBaseLayer = self._layers[Symbol.named("base")] or {}
	local newBaseLayer = {}

	for _, tableToMerge in ipairs({existingBaseLayer, data}) do
		for key, value in pairs(tableToMerge) do
			if value == self.fabric.None then
				newBaseLayer[key] = nil
			else
				newBaseLayer[key] = value
			end
		end
	end

	return self:_addLayer(Symbol.named("base"), newBaseLayer)
end

--[=[
	Removes a layer from the unit.

	@param scope string -- The scope of the layer to remove
]=]
function Unit:removeLayer(scope)
	self:assertNotDestroyed()
	return self:_removeLayer(scope)
end

function Unit:_addLayer(scope, data)
	if data == nil then
		return self:_removeLayer(scope)
	end

	if self._layers[scope] == nil then
		table.insert(self._layerOrder, scope)
	end

	self._layers[scope] = data

	-- Set up automatic layer removal if scope is a unit
	-- This lets you use a unit as a scope, and the layer gets auto removed
	-- when the unit gets removed.
	if type(scope) == "table" and getmetatable(getmetatable(scope)) == Unit then
		if self._unitScopeLayers[scope] == nil then
			self._unitScopeLayers[scope] = scope:on("destroy", function()
				self:_removeLayer(scope)
			end)
		end
	end

	self:_changed()
end

function Unit:_removeLayer(scope)
	-- Disconnect listener for layer removal if the layer is removed explicitly
	if self._unitScopeLayers[scope] then
		self._unitScopeLayers[scope]() -- This is the disconnect callback
		self._unitScopeLayers[scope] = nil
	end

	if self._layers[scope] then
		table.remove(self._layerOrder, table.find(self._layerOrder, scope))

		self._layers[scope] = nil
		self:_changed()
	end

	local shouldDestroy = next(self._layers) == nil

	if shouldDestroy then
		self:fire("destroy")
	end
end

function Unit:_runEffect(key)
	self.fabric._reactor:push(self, key)

	debug.profilebegin(("%s: Effect %s"):format(
		tostring(self),
		tostring(key)
	))

	local thread = coroutine.create(self.effects[key])
	local success, errorValue = coroutine.resume(thread, self)

	debug.profileend()

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

function Unit:_runEffects()
	if self.effects == nil then
		return
	end

	-- TODO: Document effects don't run in guaranteed order
	for key in pairs(self.effects) do
		self:_runEffect(key)
	end
end

function Unit:_changed()
	local lastData = self.data

	debug.profilebegin(("%s: reduce"):format(
		tostring(self)
	))

	local newData = self:_reduce()

	debug.profileend()

	self.data = newData

	if lastData == nil and newData ~= nil then
		self._loaded = true
		self._loading = false
		self:fire("loaded", newData)

		self:_runEffects()
	end

	if (self.shouldUpdate or Comparators.default)(newData, lastData) then
		self:fire("updated", newData, lastData)
	end
end

function Unit:_reduce()
	if next(self._layers) == nil then
		return
	end

	local values = { self._layers[Symbol.named("remote")] }
	table.insert(values, self._layers[Symbol.named("base")])

	for _, name in ipairs(self._layerOrder) do
		if RESERVED_SCOPES[name] == nil then
			table.insert(values, self._layers[name])
		end
	end

	local reducedValue = (self.reducer or Reducers.default)(values)
	local data = reducedValue

	if self.defaults and type(data) == "table" then
		data = Util.assign({}, self.defaults, reducedValue)
	end

	if self.schema then
		assert(self.schema(data))
	end

	return data
end

--[=[
	Returns true if the unit is loaded.
	Units are considered loaded after the data has been set for the first time.

	@return bool -- Whether or not the unit is loaded.
]=]
function Unit:isLoaded()
	self:assertNotDestroyed()
	return self._loaded
end

--[=[
	Sets the unit's status to `loading`. If called after the unit has already loaded, will instead throw an error.
]=]
function Unit:setIsLoading()
	self:assertNotDestroyed()
	if self._loaded then
		error("Attempt to call setIsLoading when this unit is already loaded.")
	end

	self._loading = true
end

function Unit:__tostring()
	return ("Unit(%s)"):format(
		typeof(self.ref) == "Instance" and ("%s, %s"):format(self.name, self.ref:GetFullName()) or self.name
	)
end

return Unit