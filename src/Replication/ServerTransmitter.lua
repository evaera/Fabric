local ReplicatedStorage = game:GetService("ReplicatedStorage")
local getOrCreate = require(script.Parent.getOrCreate).getOrCreate

local EVENT_NAME = "fabricEvent"

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

	self._event.OnServerEvent:Connect(function(player, namespace, eventName, ...)
		if namespace ~= self.fabric.namespace then
			return
		end

		if ServerTransmitter.Remote[eventName] then
			ServerTransmitter.Remote[eventName](self, player, ...)
		end
	end)

	self._component = fabric:registerComponent({
		name = "Transmitter";
		reducer = fabric.reducers.structure({});
		check = function(value)
			return type(value) == "table"
		end;
		onInitialize = function(component)
			component.subscribers = {}
		end;
		broadcast = function(component, transmitEvent, transmitData)
			for _, player in ipairs(component.subscribers) do
				self:_send(
					player,
					"event",
					self.fabric.serializer:serialize(component.ref),
					transmitEvent,
					transmitData
				)
			end
		end;
		sendTo = function(component, player, transmitEvent, transmitData)
			self:_send(
				player,
				"event",
				self.fabric.serializer:serialize(component.ref),
				transmitEvent,
				transmitData
			)
		end;
	})

	return setmetatable(self, ServerTransmitter)
end

function ServerTransmitter.Remote:subscribe(player, serializedComponent)
	local component = self.fabric.serializer:deserialize(serializedComponent)

	if component then
		local transmitter = component:getComponent(self._component)

		if transmitter then
			table.insert(transmitter.subscribers, player)

			transmitter:fire("subscriberAdded", player)
		end
	end
end

function ServerTransmitter.Remote:unsubscribe(player, serializedComponent)
	local component = self.fabric.serializer:deserialize(serializedComponent)

	if component then
		local transmitter = component:getComponent(self._component)

		if transmitter then
			for i, listPlayer in ipairs(transmitter.subscribers) do
				if player == listPlayer then
					table.remove(transmitter.subscribers, i)

					transmitter:fire("subscriberRemoved", player)

					break
				end
			end
		end
	end
end

function ServerTransmitter.Remote:event(player, serializedComponent, transmitEvent, transmitData)
	local component = self.fabric.serializer:deserialize(serializedComponent)

	if component then
		local transmitter = component:getComponent(self._component)

		if transmitter then
			transmitter:fire(
				"client" .. transmitEvent:sub(1, 1):upper() .. transmitEvent:sub(2),
				player,
				transmitData
			)
		end
	end
end

function ServerTransmitter:_send(player, eventName, ...)
	self._event:FireClient(player, self.fabric.namespace, eventName, ...)
end

return ServerTransmitter
