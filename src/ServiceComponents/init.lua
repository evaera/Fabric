local RunService = game:GetService("RunService")

return function(fabric)
	local deferredCreation

	fabric:on("componentRegistered", function(staticComponent)
		if staticComponent.isService == true then
			if deferredCreation == nil then
				deferredCreation = {}

				local connection

				connection = RunService.Heartbeat:Connect(function()
					connection:Disconnect()

					for _, staticComponentToCreate in ipairs(deferredCreation) do
						fabric:getOrCreateComponentByRef(staticComponentToCreate, game):mergeBaseLayer({})
					end

					deferredCreation = nil
				end)
			end

			table.insert(deferredCreation, staticComponent)
		end
	end)
end