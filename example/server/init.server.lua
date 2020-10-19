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

	onUpdated = function(self)
		print(self.ref.Name, "updated")
	end;

	effects = {
		function(self)
			if self.ref.Name == "Copy" then
				local other = fabric:getComponentByRef("Door", self.ref.Parent.Part)

				self:addLayer(self, {
					transparency = other and other:get("transparency") or 0
				})
			end
		end
	};
})

wait(.5)

local pipeline = fabric:pipelineFor(workspace:FindFirstChild("Model"):FindFirstChild("Part"), "example")

while wait(1) do
	pipeline:addLayer("Door", {
		color = BrickColor.new("Really blue")
	})
end