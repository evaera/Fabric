local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Symbol = require(script.Parent.Parent.Shared.Symbol)

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
		sendWithPredictiveLayer = function(component, layerData, transmitEvent, transmitData)
			local predictionGUID = "NetworkPredictionLayer-" .. HttpService:GenerateGUID(false)

			self:_send(
				"event",
				self.fabric.serializer:serialize(component.ref),
				transmitEvent,
				transmitData,
				predictionGUID
			)

			component.ref:addLayer(predictionGUID, layerData)
		end;
	})

	self._event.OnClientEvent:Connect(function(namespace, serializedComponent, predictionGUIDs, eventName, ...)
		if namespace ~= self.fabric.namespace then
			return
		end

		local component = self.fabric.serializer:deserialize(serializedComponent)
		assert(component ~= nil, "component is nil")

		if predictionGUIDs then
			for _, predictionGUID in ipairs(predictionGUIDs) do
				component:removeLayer(predictionGUID)
			end
		end

		if ClientTransmitter.Remote[eventName] then
			ClientTransmitter.Remote[eventName](self, component, ...)
		end
	end)

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

function ClientTransmitter:_send(eventName, serializedComponent, ...)
	self._event:FireServer(self.fabric.namespace, eventName, serializedComponent, ...)
end

function ClientTransmitter.Remote:event(component, transmitEvent, transmitData)
	local transmitter = component:getComponent(self._component)

	assert(transmitter ~= nil, "component doesn't have a transmitter")

	transmitter:fire(
		"server" .. transmitEvent:sub(1, 1):upper() .. transmitEvent:sub(2),
		transmitData
	)
end

function ClientTransmitter.Remote:rejectNetworkPrediction(component)
	self.fabric:debug(("Network prediction rejected for %q"):format(tostring(component)))
	-- no op
end

return ClientTransmitter
