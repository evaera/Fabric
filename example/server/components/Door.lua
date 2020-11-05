return {
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
			print'e'
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
				local other = self.fabric:getComponentByRef("Door", self.ref.Parent.Part)

				self:addLayer(self, {
					transparency = other and other:get("transparency") or 0
				})
			end
		end
	};
}