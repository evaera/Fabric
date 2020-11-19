local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local TagWatcher = {}
TagWatcher.__index = TagWatcher

function TagWatcher.new(fabric)
	local self = setmetatable({
		fabric = fabric;
		_tags = {};
		_deferredCreation = nil;
		_deferredRegistration = nil;
	}, TagWatcher)

	fabric:on("unitRegistered", function(staticUnit)
		if staticUnit.tag then
			if self._deferredRegistration == nil then
				self._deferredRegistration = {}

				local connection
				connection = self.fabric.Heartbeat:Connect(function()
					connection:Disconnect()

					for _, item in ipairs(self._deferredRegistration) do
						self:listenForTag(item.tag, item)
					end

					self._deferredRegistration = nil
				end)
			end

			table.insert(self._deferredRegistration, staticUnit)
		end
	end)

	return self
end

function TagWatcher:_deferCreation(staticUnit, instance, data)
	if self._deferredCreation == nil then
		self._deferredCreation = {}

		local connection
		connection = self.fabric.Heartbeat:Connect(function()
			connection:Disconnect()

			for _, item in ipairs(self._deferredCreation) do
				self.fabric:getOrCreateUnitByRef(item.staticUnit, item.instance):mergeBaseLayer(item.data)
			end

			self._deferredCreation = nil
		end)
	end

	table.insert(self._deferredCreation, {
		staticUnit = staticUnit;
		instance = instance;
		data = data;
	})
end

function TagWatcher:listenForTag(tag, staticUnit)
	self.fabric:debug("Creating units for tag", tag)
	assert(self._tags[tag] == nil, ("Tag %q is already in use!"):format(tag))
	self._tags[tag] = true

	local function addFromTag(instance)
		local data = {}

		if
			RunService:IsClient()
			and staticUnit.units
			and staticUnit.units.Replicated
		then
			-- Create unit and let Replicated unit subscribe
			self.fabric._collection:getOrCreateUnitByRef(staticUnit, instance)
		else
			if
				instance:FindFirstChild(staticUnit.name)
				and instance[staticUnit.name].ClassName == "ModuleScript"
			then
				data = require(instance[staticUnit.name])
			end

			self.fabric._collection:getOrCreateUnitByRef(staticUnit, instance)
			self:_deferCreation(staticUnit, instance, data)
		end
	end

	local function removeFromTag(instance)
		local unit = self.fabric:getUnitByRef(staticUnit, instance)

		if unit then
			unit:fire("destroy")
		end
	end

	CollectionService:GetInstanceRemovedSignal(tag):Connect(removeFromTag)
	CollectionService:GetInstanceAddedSignal(tag):Connect(addFromTag)
	for _, instance in ipairs(CollectionService:GetTagged(tag)) do
		addFromTag(instance)
	end
end

return TagWatcher
