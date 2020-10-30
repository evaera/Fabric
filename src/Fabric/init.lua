local RunService = game:GetService("RunService")

local DEFAULT_NAMESPACE = "game"

local ComponentCollection = require(script.ComponentCollection)
local Pipeline = require(script.Pipeline)
local Reactor = require(script.Reactor)
local Serializer = require(script.Serializer)

local Fabric = {
	reducers = require(script.Operators.Reducers);
	comparators = require(script.Operators.Comparators);
	DEBUG = true;
	Heartbeat = RunService.Heartbeat;
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

function Fabric:getComponentByRef(componentResolvable, ref)
	return self._collection:getComponentByRef(componentResolvable, ref)
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