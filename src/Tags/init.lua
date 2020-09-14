local TagWatcher = require(script.TagWatcher)

return function (fabric)
	fabric.tags = TagWatcher.new(fabric)
end
