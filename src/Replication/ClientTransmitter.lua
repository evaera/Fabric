local HttpService = game:GetService("HttpService")
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

	self._unit = fabric:registerUnit({
		name = "Transmitter";
		onInitialize = function(unit)
			self:subscribe(unit.ref)
		end;
		onDestroy = function(unit)
			assert(unit.ref ~= nil, "unit.ref is nil")
			self:unsubscribe(unit.ref)
		end;
		send = function(unit, transmitEvent, transmitData)
			self:_send(
				"event",
				self.fabric.serializer:serialize(unit.ref),
				transmitEvent,
				transmitData
			)
		end;
		-- Returns true if the layer is created, false if not.
		sendWithPredictiveLayer = function(unit, layerData, transmitEvent, transmitData)

			if unit.ref.data == nil then
				-- use regular send if it is loading
				unit:send(transmitEvent, transmitData)

				return false
			end

			local predictionGUID = "NetworkPredictionLayer-" .. HttpService:GenerateGUID(false)

			self:_send(
				"event",
				self.fabric.serializer:serialize(unit.ref),
				transmitEvent,
				transmitData,
				predictionGUID
			)

			unit.ref:addLayer(predictionGUID, layerData)
			return true
		end;
	})

	self._event.OnClientEvent:Connect(function(namespace, serializedUnit, predictionGUIDs, eventName, ...)
		if namespace ~= self.fabric.namespace then
			return
		end

		local unit = self.fabric.serializer:deserialize(serializedUnit)
		assert(unit ~= nil, "unit is nil")

		if predictionGUIDs then
			for _, predictionGUID in ipairs(predictionGUIDs) do
				unit:removeLayer(predictionGUID)
			end
		end

		if ClientTransmitter.Remote[eventName] then
			ClientTransmitter.Remote[eventName](self, unit, ...)
		end
	end)

	return setmetatable(self, ClientTransmitter)
end

function ClientTransmitter:subscribe(unit)
	self.fabric:debug("Subscribing to", unit.name)
	self:_send("subscribe", self.fabric.serializer:serialize(unit))
end

function ClientTransmitter:unsubscribe(unit)
	self.fabric:debug("Unsubscribing from", unit.name)
	self:_send("unsubscribe", self.fabric.serializer:serialize(unit))
end

function ClientTransmitter:_send(eventName, serializedUnit, ...)
	self._event:FireServer(self.fabric.namespace, eventName, serializedUnit, ...)
end

function ClientTransmitter.Remote:event(unit, transmitEvent, transmitData)
	local transmitter = unit:getUnit(self._unit)

	assert(transmitter ~= nil, "unit doesn't have a transmitter")

	local transmitStr = "server" .. transmitEvent:sub(1, 1):upper() .. transmitEvent:sub(2)
	transmitter:fire(
		transmitStr,
		transmitData
	)

	transmitter.ref:fire(
		transmitStr,
		transmitData
	)
end

function ClientTransmitter.Remote:rejectNetworkPrediction(unit)
	self.fabric:debug(("Network prediction rejected for %q"):format(tostring(unit)))
	unit:getUnit(self._unit):fire("rejectNetworkPrediction")
end

return ClientTransmitter
