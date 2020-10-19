local t = require(script.Parent.Parent.Parent.t)

local Types = {}

Types.ComponentDefinition = t.interface({
	-- User implementations
	name = t.string;
	reducer = t.optional(t.callback);
	check = t.optional(t.callback);
	defaults = t.optional(t.map(t.string, t.any));
	components = t.optional(t.map(t.string, t.any));
	refCheck = t.optional(t.union(t.array(t.string), t.callback));
	shouldUpdate = t.optional(t.callback);

	-- Reserved Properties
	data = t.none;
	lastData = t.none;
	fabric = t.none;
	fire = t.none;
	on = t.none;
	ref = t.none;
	-- set = t.none;
	get = t.none;
	-- getOr = t.none;
	-- getAnd = t.none;

	-- Events
	onAdded = t.optional(t.callback);
	onUpdated = t.optional(t.callback);
	onRemoved = t.optional(t.callback);
	initialize = t.optional(t.callback);
	destroy = t.optional(t.callback);

	-- Extensions
	tag = t.optional(t.string);
	chainingEvents = t.optional(t.array(t.string));
})

return Types