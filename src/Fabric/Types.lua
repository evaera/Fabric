local t = require(script.Parent.Parent.Parent.t)

local Types = {}

Types.UnitDefinition = t.interface({
	-- User implementations
	name = t.string;
	reducer = t.optional(t.callback);
	schema = t.optional(t.callback);
	defaults = t.optional(t.map(t.string, t.any));
	units = t.optional(t.map(t.string, t.any));
	refCheck = t.optional(t.union(t.array(t.string), t.callback));
	shouldUpdate = t.optional(t.callback);

	-- Reserved Properties
	data = t.none;
	lastData = t.none;
	fabric = t.none;
	fire = t.none;
	on = t.none;
	ref = t.none;
	isLoaded = t.none;
	setIsLoading = t.none;
	get = t.none;

	-- Events
	onLoaded = t.optional(t.callback);
	onUpdated = t.optional(t.callback);
	initialize = t.optional(t.callback);
	destroy = t.optional(t.callback);
	render = t.optional(t.callback);

	effects = t.optional(t.map(t.any, t.callback));

	-- Extensions
	tag = t.optional(t.string);
	chainingEvents = t.optional(t.array(t.string));
	isService = t.optional(t.boolean);
})

return Types