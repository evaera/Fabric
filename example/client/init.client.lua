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

	onInitialize = function(self)
		self.cd = Instance.new("ClickDetector")
		self.cd.Parent = self.ref

		self.cd.MouseClick:Connect(function()
			local amount = math.random()
			self.ref.Transparency = amount
			self:getComponent("Transmitter"):send("setTransparency", amount)
		end)
	end;

	onUpdated = function(self)
		self.ref.Transparency = self:get("transparency") or 0
		self.ref.BrickColor = self:get("color") or BrickColor.new("Really red")
	end
})