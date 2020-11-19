return {
	name = "Door";
	tag = "Door";

	units = {
		Replicated = {};
	};

	defaults = {
		transparency = 0;
	};

	onInitialize = function(self)

	end;

	onClientSetTransparency = function(self, _player, amount)
		if math.random() > 0.2 then
			self:addLayer(self, {
				transparency = amount
			})
		else
			print("Ignore")
		end
	end;

	onUpdated = function(self)
		print(self.ref.Name, "updated")
	end;
}