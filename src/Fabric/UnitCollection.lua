local Unit = require(script.Parent.Unit)
local Types = require(script.Parent.Types)
local isAllowedOnRef = require(script.Parent.isAllowedOnRef).isAllowedOnRef

local WEAK_KEYS_METATABLE = {
	__mode = "k"
}

local UnitCollection = {}
UnitCollection.__index = UnitCollection

function UnitCollection.new(fabric)
	return setmetatable({
		fabric = fabric;
		_unitsByName = {};
		_unitsByRef = {};
		_refUnits = {};
	}, UnitCollection)
end

function UnitCollection:register(unitDefinition, isHotReload)
	assert(Types.UnitDefinition(unitDefinition))

	if not isHotReload then
		assert(self._unitsByName[unitDefinition.name] == nil, "A unit with this name is already registered!")
	end

	self.fabric.Unit[unitDefinition.name] = unitDefinition

	setmetatable(unitDefinition, Unit)
	unitDefinition.__index = unitDefinition
	unitDefinition.__tostring = Unit.__tostring
	unitDefinition.fabric = self.fabric

	unitDefinition.new = function()
		return setmetatable({}, unitDefinition)
	end

	self._unitsByName[unitDefinition.name] = unitDefinition
	self._unitsByRef[unitDefinition] = unitDefinition
end

function UnitCollection:resolve(unitResolvable)
	return self._unitsByRef[unitResolvable]
		or self._unitsByName[unitResolvable]
end

function UnitCollection:resolveOrError(unitResolvable)
	return self:resolve(unitResolvable) or error(
		("Cannot resolve unit %s"):format(tostring(unitResolvable))
	)
end

function UnitCollection:constructUnit(staticUnit, ref)
	assert(isAllowedOnRef(staticUnit, ref))

	local unit = staticUnit.new()

	assert(
		getmetatable(unit) == staticUnit,
		"Metatable of newly constructed unit must be its static counterpart"
	)

	unit.private = {}
	unit._layers = {}
	unit._layerOrder = {}
	unit._reactsTo = setmetatable({}, WEAK_KEYS_METATABLE)
	unit._unitScopeLayers = {}
	unit._listeners = {}
	unit.ref = ref
	unit.fabric = self.fabric
	unit._loading = false
	unit._loaded = false

	self._refUnits[ref] = self._refUnits[ref] or {}
	self._refUnits[ref][staticUnit] = unit

	unit:on("destroy", function()
		self:deconstructUnit(unit)
	end)

	if staticUnit.units then
		for name, data in pairs(staticUnit.units) do
			unit:getOrCreateUnit(name):mergeBaseLayer(data)
		end
	end

	unit:fire("initialize")

	return unit
end

-- Need a way to hook into that and make sure units being removed is
-- identical to unit having all data set to nil
-- Perhaps a unit:destroy() method is necessary after all
function UnitCollection:deconstructUnit(unit)
	local staticUnit = getmetatable(unit)

	self._refUnits[unit.ref][staticUnit] = nil

	if next(self._refUnits[unit.ref]) == nil then
		self._refUnits[unit.ref] = nil
	end

	self:removeAllUnitsWithRef(unit)

	unit._listeners = nil
	unit.ref = nil
	unit._destroyed = true
	unit._layers = nil
	unit._layerOrder = nil
	unit._reactsTo = nil

	for _, disconnect in pairs(unit._unitScopeLayers) do
		disconnect()
	end

	unit._unitScopeLayers = nil
end

function UnitCollection:getUnitByRef(unitResolvable, ref)
	local staticUnit = self:resolveOrError(unitResolvable)

	return self._refUnits[ref] and self._refUnits[ref][staticUnit]
end

function UnitCollection:getOrCreateUnitByRef(unitResolvable, ref)
	local unit = self:getUnitByRef(unitResolvable, ref)

	if not unit then
		unit = self:constructUnit(self:resolveOrError(unitResolvable), ref)
	end

	return unit
end

function UnitCollection:removeAllUnitsWithRef(ref)
	if self._refUnits[ref] then
		for _staticUnit, unit in pairs(self._refUnits[ref]) do
			unit:fire("destroy")
		end
	end
end

return UnitCollection
