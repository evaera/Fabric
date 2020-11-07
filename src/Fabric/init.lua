local RunService = game:GetService("RunService")

local DEFAULT_NAMESPACE = "game"

local Promise = require(script.Parent.Parent.Promise)

local ComponentCollection = require(script.ComponentCollection)
local Pipeline = require(script.Pipeline)
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

function Fabric:pipelineFor(ref, scope)
	return Pipeline.new(self, ref, scope)
end

function Fabric:registerComponent(componentDefinition)
	assert(componentDefinition ~= nil, "componentDefinition is nil")
	self._collection:register(componentDefinition)

	self:fire("componentRegistered", componentDefinition)

	return componentDefinition
end

function Fabric:registerComponentsIn(container)
	for _, object in ipairs(container:GetChildren()) do
		if object:IsA("ModuleScript") then
			if not object.Name:match("%.spec$") then
				local componentDefinition = require(object)
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

function Fabric:getComponentByRef(componentResolvable, ref)
	return self._collection:getComponentByRef(componentResolvable, ref)
end

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

			component:on("loadingFailed", function(...)
				reject(...)
			end)
		end
	end)
end

function Fabric:removeAllComponentsWithRef(ref)
	self._collection:removeAllComponentsWithRef(ref)
end

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

function Fabric:debug(...)
	if self.DEBUG then
		warn("[Fabric]", ...)
	end
end

return Fabric