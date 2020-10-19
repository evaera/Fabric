local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EVENT_NAME = "fabricEvent"

local ClientTransmitter = {
	Remote = {};
}
ClientTransmitter.__index = ClientTransmitter

function ClientTransmitter.new(fabric)
	local self = {
		fabric = fabric;
	}

	self._event = ReplicatedStorage:WaitForChild(EVENT_NAME)

	self._event.OnClientEvent:Connect(function(namespace, eventName, ...)
		if namespace ~= self.fabric.namespace then
			return
		end

		if ClientTransmitter.Remote[eventName] then
			ClientTransmitter.Remote[eventName](self, ...)
		end
	end)

	self._component = fabric:registerComponent({
		name = "Transmitter";
		onInitialize = function(component)
			self:subscribe(component.ref)
		end;
		onDestroy = function(component)
			assert(component.ref ~= nil, "component.ref is nil")
			self:unsubscribe(component.ref)
		end;
		send = function(component, transmitEvent, transmitData)
			self:_send(
				"event",
				self.fabric.serializer:serialize(component.ref),
				transmitEvent,
				transmitData
			)
		end;
	})

	return setmetatable(self, ClientTransmitter)
end

function ClientTransmitter:subscribe(component)
	self.fabric:debug("Subscribing to", component.name)
	self:_send("subscribe", self.fabric.serializer:serialize(component))
end

function ClientTransmitter:unsubscribe(component)
	self.fabric:debug("Unsubscribing from", component.name)
	self:_send("unsubscribe", self.fabric.serializer:serialize(component))
end

function ClientTransmitter:_send(eventName, ...)
	self._event:FireServer(self.fabric.namespace, eventName, ...)
end

function ClientTransmitter.Remote:event(serializedComponent, transmitEvent, transmitData)
	local component = self.fabric.serializer:deserialize(serializedComponent)

	assert(component ~= nil, "component is nil")

	local transmitter = component:getComponent(self._component)

	assert(transmitter ~= nil, "component doesn't have a transmitter")

	transmitter:fire(
		"server" .. transmitEvent:sub(1, 1):upper() .. transmitEvent:sub(2),
		transmitData
	)
end

return ClientTransmitter
