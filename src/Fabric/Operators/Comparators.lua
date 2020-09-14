local Util = require(script.Parent.Parent.Parent.Shared.Util)

local COMPARATOR_NEAR_DEFAULT = 0.001

local Comparators = {}

function Comparators.reference(a, b)
	return a ~= b
end

function Comparators.value(a, b)
	return not Util.deepEquals(a, b)
end

function Comparators.within(epsilon)
	return function(a, b)
		return math.abs(a - b) > epsilon
	end
end

function Comparators.structure(propertyComparators)
	return function (a, b)
		for _, item in ipairs({a, b}) do
			for key in pairs(item) do
				if (propertyComparators[key] or Comparators.default)(a and a[key], b and b[key]) then
					return true
				end
			end
		end

		return false
	end
end

Comparators.near = Comparators.within(COMPARATOR_NEAR_DEFAULT)

Comparators.default = Comparators.reference

return Comparators
