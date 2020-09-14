local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FabricLib = require(ReplicatedStorage.Fabric)

local fabric = FabricLib.Fabric.new("example")
FabricLib.useReplication(fabric)
FabricLib.useTags(fabric)

fabric:registerComponent({
	name = "Door";
	tag = "Door";

	components = {
		Replicated = {};
	};

	defaults = {
		transparency = 0;
	};
})

wait(.5)

local pipeline = fabric:pipelineFor(workspace.Model.Part, "example")

while wait(1) do
	pipeline:addLayer("Door", {
		transparency = math.random()
	})
end