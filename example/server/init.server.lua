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

	onInitialize = function(self)
		self:getComponent("Transmitter"):on("clientSetTransparency", function(_, amount)
			self:addLayer(self, {
				transparency = amount
			})
		end)
	end;
})

wait(.5)

local pipeline = fabric:pipelineFor(workspace:FindFirstChild("Model"):FindFirstChild("Part"), "example")

while wait(1) do
	pipeline:addLayer("Door", {
		color = BrickColor.new("Really blue")
	})
end