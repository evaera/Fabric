local RunService = game:GetService("RunService")
local Util = require(script.Parent.Parent.Shared.Util)
local Symbol = require(script.Parent.Parent.Shared.Symbol)

return function (fabric)
	fabric:registerComponent(Util.assign(
		{},
		{
			name = "Replicated";
			reducer = fabric.reducers.structure({});
			check = function(value)
				return type(value) == "table"
			end;
			onInitialize = function(self)
				self.transmitter = self.ref:getOrCreateComponent("Transmitter")

				self:on("destroy", self.transmitter:on("subscriberAdded", function(player)
					self.transmitter:sendTo(player, "replicate", {
						data = self.ref.data
					})
				end))

				if RunService:IsClient() then
					self.transmitter:on("serverReplicate", function(payload)
						self.ref:_addLayer(Symbol.named("remote"), payload.data)
					end)
				end
			end;
		},
		RunService:IsServer() and {
			onAdded = function(self)
				self:on("destroy", self.ref:on("updated", function(data)
					self.transmitter:broadcast("replicate", {
						data = data;
					})
				end))
			end;
		} or {}
	))
end