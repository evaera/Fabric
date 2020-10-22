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

			assert(ref ~= nil, ("Attempt to deserialize a %q component on a ref that's not present in this realm."):format(
				tostring(data.name)
			))

			return fabric._collection:getComponentByRef(data.name, ref) or error(
				("Attempt to deserialize component %q on %q, but it does not exist in this realm."):format(
					tostring(data.name),
					tostring(ref)
				)
			)
		end
	};
}
