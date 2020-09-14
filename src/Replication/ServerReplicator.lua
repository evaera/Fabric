local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Serializer = require(script.Parent.Serializer)
local Util = require(script.Parent.Util)

local EVENT_NAME = "fabricEvent"

local ServerReplicator = {
	Remote = {}
}
ServerReplicator.__index = ServerReplicator

local function identity(...)
	return ...
end

local function getOrCreate(parent, name, class)
	local instance = parent:FindFirstChild(name)

	if not instance then
		instance = Instance.new(class)
		instance.Name = name
		instance.Parent = parent
	end

	return instance
end


function ServerReplicator.new(fabric)
	local self = {
		fabric = fabric;
		serializer = Serializer.new(fabric);
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

		if ServerReplicator.Remote[eventName] then
			ServerReplicator.Remote[eventName](self, player, ...)
		end
	end)

	self._component = fabric:registerComponent({
		name = "Replicated";
		reducer = fabric.reducers.structure({});
		check = function(value)
			return type(value) == "table"
		end;
		onInitialize = function(component)
			component.subscribers = {}
		end;
		onUpdated = function(component)

		end;
		onParentUpdated = function(component)
			for _, player in ipairs(component.subscribers) do
				self:_replicateComponent(player, component.ref)
			end
		end;
	})


	return setmetatable(self, ServerReplicator)
end

function ServerReplicator.Remote:subscribe(player, serializedComponent)
	local component = self.serializer:deserialize(serializedComponent)

	if component then
		local replicatedComponent = self.fabric:getComponentByRef(self._component, component)

		if replicatedComponent then
			self:_replicateComponent(player, component)

			table.insert(replicatedComponent.subscribers, player)
		end
	end
end

function ServerReplicator.Remote:unsubscribe(player, serializedComponent)
	local component = self.serializer:deserialize(serializedComponent)

	if component then
		local replicatedComponent = self.fabric:getComponentByRef(self._component, component)

		if replicatedComponent then
			for i, listPlayer in ipairs(replicatedComponent.subscribers) do
				if player == listPlayer then
					table.remove(replicatedComponent.subscribers, i)
					break
				end
			end
		end
	end
end

function ServerReplicator:_send(player, eventName, ...)
	self._event:FireClient(player, self.fabric.namespace, eventName, ...)
end

function ServerReplicator:_replicateComponent(player, component)
	return self:_send(player, "replicateComponents", {{
		component = self.serializer:serialize(component);
		data = component.data;
		-- createIfNotExists: component name
	}})
end

return ServerReplicator
