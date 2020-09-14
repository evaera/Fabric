local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Serializer = require(script.Parent.Serializer)
local Util = require(script.Parent.Util)
local Symbol = require(script.Parent.Parent.Shared.Symbol)

local EVENT_NAME = "fabricEvent"

local ClientReplicator = {
	Remote = {};
}
ClientReplicator.__index = ClientReplicator

function ClientReplicator.new(fabric)
	local self = {
		fabric = fabric;
		serializer = Serializer.new(fabric);
	}

	self._event = ReplicatedStorage:WaitForChild(EVENT_NAME)

	self._event.OnClientEvent:Connect(function(namespace, eventName, ...)
		if namespace ~= self.fabric.namespace then
			return
		end

		if ClientReplicator.Remote[eventName] then
			ClientReplicator.Remote[eventName](self, ...)
		end
	end)

	self._component = fabric:registerComponent({
		name = "Replicated";
		onAdded = function(component)
			self:subscribe(component.ref)
		end;
		onDestroy = function(component)
			assert(component.ref ~= nil)
			self:unsubscribe(component.ref)
		end;
	})

	return setmetatable(self, ClientReplicator)
end

function ClientReplicator:subscribe(component)
	self.fabric:debug("Subscribing to", component.name)
	self:_send("subscribe", self.serializer:serialize(component))
end

function ClientReplicator:unsubscribe(component)
	self.fabric:debug("Unsubscribing from", component.name)
	self:_send("unsubscribe", self.serializer:serialize(component))
end

function ClientReplicator:_send(eventName, ...)
	self._event:FireServer(self.fabric.namespace, eventName, ...)
end

function ClientReplicator.Remote:replicateComponents(components)
	for _, entry in ipairs(components) do
		local component = self.serializer:deserialize(entry.component)

		assert(component ~= nil)

		self.fabric:pipelineFor(component.ref, Symbol.named("remote")):addLayer(component.name, entry.data)
	end
end

return ClientReplicator
