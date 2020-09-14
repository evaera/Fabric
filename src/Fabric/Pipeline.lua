local Symbol = require(script.Parent.Parent.Shared.Symbol)

local Pipeline = {}
Pipeline.__index = Pipeline

function Pipeline.new(fabric, ref, scope)
	return setmetatable({
		fabric = fabric;
		ref = ref;
		scope = scope;
	}, Pipeline)
end

function Pipeline:addLayer(componentResolvable, data)
	local component = self.fabric._collection:getOrCreateComponentByRef(componentResolvable, self.ref)

	component:_addLayer(self.scope, data)

	return component
end

function Pipeline:removeLayer(componentResolvable)
	local component = self.fabric._collection:getComponentByRef(componentResolvable, self.ref)

	if not component then
		return
	end

	component:_removeLayer(self.scope)
end

function Pipeline:setBaseLayer(componentResolvable, data)
	local component = self.fabric._collection:getOrCreateComponentByRef(componentResolvable, self.ref)

	component:_addLayer(Symbol.named("base"), data)

	return component
end

function Pipeline:getScope(newScope)
	return self.fabric:pipelineFor(self.ref, newScope)
end

function Pipeline:__tostring()
	return ("Pipeline(%s -> %s)"):format(
		tostring(self.scope),
		tostring(self.ref)
	)
end

return Pipeline