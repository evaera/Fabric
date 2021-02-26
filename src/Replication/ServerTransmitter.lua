local ReplicatedStorage = game:GetService("ReplicatedStorage")
local getOrCreate = require(script.Parent.getOrCreate).getOrCreate
local FailMode = require(script.Parent.Parent.Fabric.Serializer).FailMode

local EVENT_NAME = "fabricEvent"

local EVENT_FAIL_MODES = {
	unsubscribe = FailMode.Ignore;
}

local ServerTransmitter = {
	Remote = {}
}
ServerTransmitter.__index = ServerTransmitter

function ServerTransmitter.new(fabric)
	local self = {
		fabric = fabric;
	}

	self._event = getOrCreate(
		ReplicatedStorage,
		EVENT_NAME,
		"RemoteEvent"
	)

	self._unit = fabric:registerUnit({
		name = "Transmitter";
		reducer = fabric.reducers.structure({});
		schema = function(value)
			return type(value) == "table"
		end;
		onInitialize = function(unit)
			unit.subscribers = {}
		end;
		broadcast = function(unit, transmitEvent, transmitData)
			for _, player in ipairs(unit.subscribers) do
				self:_send(
					unit,
					player,
					"event",
					transmitEvent,
					transmitData
				)
			end
		end;
		sendTo = function(unit, player, transmitEvent, transmitData)
			self:_send(
				unit,
				player,
				"event",
				transmitEvent,
				transmitData
			)
		end;
	})

	self._event.OnServerEvent:Connect(function(player, namespace, eventName, serializedUnit, ...)
		if namespace ~= self.fabric.namespace then
			return
		end

		if ServerTransmitter.Remote[eventName] then
			local transmitter = self:_getTransmitterFromSerializedUnit(
				serializedUnit,
				EVENT_FAIL_MODES[eventName] or FailMode.Error
			)

			ServerTransmitter.Remote[eventName](self, player, transmitter, ...)
		end
	end)

	return setmetatable(self, ServerTransmitter)
end

function ServerTransmitter:_getTransmitterFromSerializedUnit(serializedUnit, failMode)
	local unit = self.fabric.serializer:deserialize(serializedUnit, failMode)

	if not unit then
		self.fabric:debug(("Client wants communicate with unit %q on %q, but that doesn't exist on the server. This could be normal if the attached Instance was removed."):format(
				tostring(serializedUnit.name),
				tostring(serializedUnit.ref)
			))
		return
	end

	local transmitter = unit:getUnit(self._unit)

	if not transmitter then
		self.fabric:debug(("%s does not have a Transmitter attached, but received a message."):format(unit))
	end

	return transmitter
end

function ServerTransmitter.Remote:subscribe(player, transmitter)
	table.insert(transmitter.subscribers, player)

	transmitter:fire("subscriberAdded", player)
end

-- TODO: Make sure players who leave the game get removed from subscribers
function ServerTransmitter.Remote:unsubscribe(player, transmitter)
	if transmitter == nil then
		return
	end

	for i, listPlayer in ipairs(transmitter.subscribers) do
		if player == listPlayer then
			table.remove(transmitter.subscribers, i)

			transmitter:fire("subscriberRemoved", player)

			break
		end
	end
end

function ServerTransmitter.Remote:event(player, transmitter, transmitEvent, transmitData, predictionGUID)
	if type(predictionGUID) == "string" then
		if transmitter.predictionGUIDBuffer == nil then
			transmitter.predictionGUIDBuffer = {}

			local connection
			connection = transmitter.fabric.Heartbeat:Connect(function()
				connection:Disconnect()

				if #transmitter.predictionGUIDBuffer > 0 then
					self:_send(transmitter, player, "rejectNetworkPrediction")
				end

				transmitter.predictionGUIDBuffer = nil
			end)
		end

		table.insert(transmitter.predictionGUIDBuffer, predictionGUID)
	end

	local transmitStr = "client" .. transmitEvent:sub(1, 1):upper() .. transmitEvent:sub(2)
	transmitter:fire(
		transmitStr,
		player,
		transmitData
	)

	transmitter.ref:fire(
		transmitStr,
		player,
		transmitData
	)
end

function ServerTransmitter:_send(transmitter, player, eventName, ...)
	self._event:FireClient(
		player,
		self.fabric.namespace,
		self.fabric.serializer:serialize(transmitter.ref),
		transmitter.predictionGUIDBuffer,
		eventName,
		...
	)

	if transmitter.predictionGUIDBuffer then
		transmitter.predictionGUIDBuffer = {}
	end
end

return ServerTransmitter
