local BuiltInSerializers = require(script.Parent.BuiltInSerializers)
local makeEnum = require(script.Parent.makeEnum).makeEnum

local Serializer = {
	FailMode = makeEnum("FailMode", {"Error", "Ignore"});
}
Serializer.__index = Serializer

function Serializer.new(fabric)
	return setmetatable({
		_serializers = setmetatable({}, {__index = BuiltInSerializers.serializers});
		_deserializers = setmetatable({}, {__index = BuiltInSerializers.deserializers});
		fabric = fabric;
	}, Serializer)
end

function Serializer:deserialize(serializedTarget, failMode)
	if type(serializedTarget) ~= "table" then
		return serializedTarget
	end

	local deserializer = self._deserializers[serializedTarget.type]
	if not deserializer then
		error("Unable to deserialize object") -- TODO: Dump inspect of object
	end

	local object = deserializer(serializedTarget, self.fabric)

	if object == nil and failMode == Serializer.FailMode.Error then
		error("Deserialization failed for object and no error was emitted by the deserializer. This is a bug in your deserializer!")
	end

	return object
end

function Serializer:serialize(object)
	if type(object) ~= "table" then
		return object
	end

	local serializer = self:findSerializer(object)

	return
		serializer and serializer(object, self.fabric)
		or error(("Unable to serialize replicated unit %s"):format(tostring(object)))
end

function Serializer:registerSerializer(class, callback)
	self._serializers[class] = callback
end

function Serializer:registerDeserializer(name, callback)
	assert(type(name) == "string", "Deserializer type must be a string")
	self._deserializers[name] = callback
end

local function find(class, map)
	if map[class] then
		return map[class]
	end

	local metatable = getmetatable(class)

	if metatable then
		return find(metatable, map)
	end
end

function Serializer:findSerializer(class)
	return find(class, self._serializers)
end

function Serializer:findDeserializer(name)
	return self._deserializers[name]
end

return Serializer