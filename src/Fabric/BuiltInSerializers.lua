local Unit = require(script.Parent.Unit)

return {
	serializers = {
		[Unit] = function(unit, fabric)

			return {
				type = "_unit";
				name = unit.name;
				ref = fabric.serializer:serialize(unit.ref);
			}
		end
	};

	deserializers = {
		_unit = function(data, fabric)
			local ref = fabric.serializer:deserialize(data.ref)

			assert(ref ~= nil, ("Attempt to deserialize a %q unit on a ref that's not present in this realm."):format(
				tostring(data.name)
			))

			return fabric._collection:getUnitByRef(data.name, ref) or error(
				("Attempt to deserialize unit %q on %q, but it does not exist in this realm."):format(
					tostring(data.name),
					tostring(ref)
				)
			)
		end
	};
}
