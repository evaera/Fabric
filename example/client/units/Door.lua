return {
	name = "Door";
	tag = "Door";

	units = {
		Replicated = {};
	};

	onInitialize = function(self)
		self.cd = Instance.new("ClickDetector")
		self.cd.Parent = self.ref

		self.cd.MouseClick:Connect(function()
			local amount = math.random()
			self:getUnit("Transmitter"):sendWithPredictiveLayer({
				transparency = amount
			}, "setTransparency", amount)
		end)
	end;

	onUpdated = function(self)
		print(self)
	end,

	effects = {
		-- Each effect only runs if the key it accesses with :get actually changes
		function(self)
			self.ref.Transparency = self:get("transparency") or 0

			self.x = (self.x or 0) + 1

			print(self.x)
		end,
		function(self)
			self.ref.BrickColor = self:get("color") or BrickColor.new("Really red")
		end,
	}
}