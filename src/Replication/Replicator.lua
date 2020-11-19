local RunService = game:GetService("RunService")
local Util = require(script.Parent.Parent.Shared.Util)
local Symbol = require(script.Parent.Parent.Shared.Symbol)

return function (fabric)
	fabric:registerUnit(Util.assign(
		{},
		{
			name = "Replicated";
			reducer = fabric.reducers.structure({});
			schema = function(value)
				return type(value) == "table"
			end;
			onInitialize = function(self)
				self.transmitter = self.ref:getOrCreateUnit("Transmitter")
				self.initialBroadcastSent = false

				self:on("destroy", self.transmitter:on("subscriberAdded", function(player)
					if self.initialBroadcastSent then
						self.transmitter:sendTo(player, "replicate", {
							data = self.ref.data
						})
					end
				end))

				if RunService:IsClient() then
					self.ref:setIsLoading()

					self.transmitter:on("serverReplicate", function(payload)
						self.ref:_addLayer(Symbol.named("remote"), payload.data)
					end)
				end
			end;
		},
		RunService:IsServer() and {
			onLoaded = function(self)
				self:on("destroy", self.ref:on("updated", function()
					self.initialBroadcastSent = true

					self.transmitter:broadcast("replicate", {
						data = self.ref.data;
					})
				end))
			end;
		} or {}
	))
end