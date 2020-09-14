local RunService = game:GetService("RunService")

local Component = require(script.Parent.Parent.Fabric.Component)

return {
	serializers = {
		[Component] = function(component, fabric)

			return {
				type = "_component";
				name = component.name;
				ref = fabric.replicator.serializer:serialize(component.ref);
			}
		end
	};

	deserializers = {
		_component = function(data, fabric)
			local ref = fabric.replicator.serializer:deserialize(data.ref)

			return fabric._collection:getComponentByRef(data.name, ref) or error(
				("Component %q does not currently exist (deserialization)"):format(
					tostring(data.name)
				)
			)
		end
	};
}
