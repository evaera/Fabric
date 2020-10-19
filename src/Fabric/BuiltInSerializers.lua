local Component = require(script.Parent.Component)

return {
	serializers = {
		[Component] = function(component, fabric)

			return {
				type = "_component";
				name = component.name;
				ref = fabric.serializer:serialize(component.ref);
			}
		end
	};

	deserializers = {
		_component = function(data, fabric)
			local ref = fabric.serializer:deserialize(data.ref)

			return fabric._collection:getComponentByRef(data.name, ref) or error(
				("Component %q does not currently exist (deserialization)"):format(
					tostring(data.name)
				)
			)
		end
	};
}
