local RunService = game:GetService("RunService")

local DEFAULT_NAMESPACE = "game"

local Promise = require(script.Parent.Parent.Promise)

local ComponentCollection = require(script.ComponentCollection)
local Reactor = require(script.Reactor)
local Serializer = require(script.Serializer)
local HotReloader = require(script.HotReloader)
local Symbol = require(script.Parent.Shared.Symbol)

local Fabric = {
	reducers = require(script.Operators.Reducers);
	comparators = require(script.Operators.Comparators);
	t = require(script.Parent.Parent.t);
	DEBUG = true;
	Heartbeat = RunService.Heartbeat;
	None = Symbol.named("None");
	Component = setmetatable({}, {
		__index = function(_, key)
			error(("Component %q is not registered!"):format(key))
		end
	});
}
Fabric.__index = Fabric

function Fabric.new(namespace)
	local self = setmetatable({
		namespace = namespace or DEFAULT_NAMESPACE;
		_listeners = {};
	}, Fabric)

	self.serializer = Serializer.new(self)
	self._collection = ComponentCollection.new(self)
	self._reactor = Reactor.new(self)

	if RunService:IsStudio() then
		self._hotReloader = HotReloader.new(self)
	end

	return self
end

--[=[
	Registers a component. This function should be called before attempting to get or create the component.

	@param componentDefinition ComponentDefinition -- The definition of the component
	@return ComponentDefinition -- The passed component definition
]=]
function Fabric:registerComponent(componentDefinition)
	assert(componentDefinition ~= nil, "componentDefinition is nil")
	self._collection:register(componentDefinition)

	self:fire("componentRegistered", componentDefinition)

	return componentDefinition
end

--[=[
	Registers all components that are immmediate children of a container.
	Skips any test scripts (i.e. name of form `*.spec`) in the container.

	@param container Instance -- The container
	@return nil
]=]
function Fabric:registerComponentsIn(container)
	for _, object in ipairs(container:GetChildren()) do
		if object:IsA("ModuleScript") then
			if not object.Name:match("%.spec$") then
				local componentDefinition = require(object)

				if componentDefinition.name == nil then
					componentDefinition.name = object.Name
				end

				self:registerComponent(componentDefinition)

				if self._hotReloader then
					self._hotReloader:giveModule(object, componentDefinition)
				end
			end
		else
			self:registerComponentsIn(object)
		end
	end
end

--[=[
	Returns the component associated with a component resolvable that is attached to a ref,
	or nil if it doesn't exist.

	@param componentResolvable ComponentResolvable -- The component to retrieve
	@param ref Ref -- The ref to retrieve the component from
	@return Component? -- The attached component
]=]
function Fabric:getComponentByRef(componentResolvable, ref)
	return self._collection:getComponentByRef(componentResolvable, ref)
end

--[=[
	Returns the component associated with a component resolvable that is attached to ref.
	If it does not exist, then creates and attaches the component to ref and returns it.

	@param componentResolvable ComponentResolvable -- The component to retrieve
	@param ref Ref -- The ref to retrieve the attached component from
	@return Component -- The attached component
]=]
function Fabric:getOrCreateComponentByRef(componentResolvable, ref)
	return self._collection:getOrCreateComponentByRef(componentResolvable, ref)
end

function Fabric:getLoadedComponentByRef(componentResolvable, ref)
	local component = self._collection:getComponentByRef(componentResolvable, ref)

	if component == nil then
		error(("Attempt to get loaded component %q on %s, but it does not exist."):format(
			tostring(componentResolvable),
			tostring(ref)
		))
	end

	if not (component._loaded or component._loading) then
		error(("Attempt to call getLoadedComponentByRef on %q on %s, but it will never be loaded."):format(
			tostring(componentResolvable),
			tostring(ref)
		))
	end

	return Promise.new(function(resolve, reject)
		if component._loaded then
			return resolve(component)
		else
			component:on("loaded", function()
				resolve(component)
			end)

			-- This must be fired by the user. It's not fired anywhere inside the Fabric library.
			component:on("loadingFailed", function(...)
				reject(...)
			end)
		end
	end)
end

--[=[
	Removes all components attached to the passed ref.

	@param ref Ref -- The ref to remove all components from
	@return nil
]=]
function Fabric:removeAllComponentsWithRef(ref)
	self._collection:removeAllComponentsWithRef(ref)
end

--[=[
	Fires a fabric event.

	@param eventName string -- The event name to fire
	@param ... any -- The arguments to fire the event with.
	@return nil
]=]
function Fabric:fire(eventName, ...)
	if not self._listeners[eventName] then
		return -- Do nothing if no listeners registered
	end

	for _, callback in ipairs(self._listeners[eventName]) do
		local success, errorValue = coroutine.resume(coroutine.create(callback), ...)

		if not success then
			warn(("Event listener for %s encountered an error: %s"):format(
				tostring(eventName),
				tostring(errorValue)
			))
		end
	end
end

--[=[
	Listens to a fabric event.

	@param eventName string -- The event name to listen to
	@param callback function -- The callback fired
	@return nil
]=]
function Fabric:on(eventName, callback)
	self._listeners[eventName] = self._listeners[eventName] or {}
	table.insert(self._listeners[eventName], callback)

	return function()
		for i, listCallback in ipairs(self._listeners[eventName]) do
			if listCallback == callback then
				table.remove(self._listeners[eventName], i)
				break
			end
		end
	end
end

--[=[
	Logs a debug message. Set fabric.DEBUG = true to enable.

	@param ... any -- The debug information to log
	@return nil
]=]
function Fabric:debug(...)
	if self.DEBUG then
		warn("[Fabric]", ...)
	end
end

return Fabric