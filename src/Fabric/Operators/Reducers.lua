local Util = require(script.Parent.Parent.Parent.Shared.Util)

local Reducers = {}

function Reducers.last(values)
	return values[#values]
end

function Reducers.first(values)
	return values[1]
end

function Reducers.truthy(values)
	for _, value in ipairs(values) do
		if value then
			return value
		end
	end
end

function Reducers.falsy(values)
	for _, value in ipairs(values) do
		if not value then
			return value
		end
	end
end

function Reducers.add(values)
	local reducedValue = 0

	for _, value in ipairs(values) do
		reducedValue = reducedValue + value
	end

	return reducedValue
end

function Reducers.multiply(values)
	local reducedValue = 1

	for _, value in ipairs(values) do
		reducedValue = reducedValue * value
	end

	return reducedValue
end

function Reducers.concatArray(values)
	return Util.concat(unpack(values))
end

function Reducers.collect(values)
	return values
end

function Reducers.lowest(values)
	if #values == 0 then
		return
	end

	return math.min(unpack(values))
end

function Reducers.highest(values)
	if #values == 0 then
		return
	end

	return math.max(unpack(values))
end

function Reducers.mergeTable(values)
	return Util.assign({}, unpack(values))
end

-- Utilities

function Reducers.concatString(delim)
	return function (values)
		return table.concat(values, delim or "")
	end
end

function Reducers.priorityValue(reducer)
	reducer = reducer or Reducers.last

	return function (values)

		local highestPriority = -math.huge
		local highestPriorityValues = {}

		for _, struct in ipairs(values) do
			if struct.priority > highestPriority then
				highestPriorityValues = {struct.value}
			elseif struct.priority == highestPriority then
				table.insert(highestPriorityValues, struct.value)
			end
		end

		return reducer(highestPriorityValues)
	end
end

function Reducers.structure(reducers, default)
	local passthrough = reducers == nil and default == nil

	if default == nil then
		default = Reducers.last
	end

	return function(values)
		if passthrough then
			if #values == 1 then
				return values[1]
			else
				return Util.assign({}, unpack(values))
			end
		end

		local properties = {}

		for _, value in ipairs(values) do
			for propName, propValue in pairs(value) do
				if properties[propName] == nil then
					properties[propName] = {}
				end

				table.insert(properties[propName], propValue)
			end
		end

		local reducedValue = {}

		for propName, propValues in pairs(properties) do
			reducedValue[propName] =
				(reducers[propName] or default)(propValues, properties)
		end

		return reducedValue
	end
end

-- TODO: structure with unknown fields using one
function Reducers.map(reducer, ...)
	return Reducers.structure({}, reducer, ...)
end

function Reducers.exactly(value)
	return function ()
		return value
	end
end

function Reducers.try(...)
	local reducers = {...}

	return function (values)
		for _, reducer in ipairs(reducers) do
			local result = reducer(values)

			if result ~= nil then
				return result
			end
		end

		return nil
	end
end

function Reducers.compose(...)
	local reducers = {...}

	return function (values)
		for _, reducer in ipairs(reducers) do
			values = reducer(values)
		end

		return values
	end
end

--? Should this be removed in favor of Reducers.try?
function Reducers.thisOr(reducer, defaultValue)
	return function(values)
		local result = reducer(values)

		if result == nil then
			return defaultValue
		else
			return result
		end
	end
end

local function makeOr(func)
	return function (defaultValue)
		return Reducers.thisOr(func, defaultValue)
	end
end

Reducers.truthyOr = makeOr(Reducers.truthy)
Reducers.falsyOr = makeOr(Reducers.falsy)
Reducers.lastOr = makeOr(Reducers.last)
Reducers.default = Reducers.structure()

return Reducers
