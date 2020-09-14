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

	onUpdated = function(self)
		self.ref.Transparency = self:get("transparency") or 0
		self.ref.BrickColor = BrickColor.new("Really red")
	end
})