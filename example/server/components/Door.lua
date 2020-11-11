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
			if math.random() > 0.5 then
				self:addLayer(self, {
					transparency = amount
				})
			else
				print("Ignore")
			end
		end)
	end;

	onUpdated = function(self)
		print(self.ref.Name, "updated")
	end;
}