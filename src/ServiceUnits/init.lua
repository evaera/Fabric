local RunService = game:GetService("RunService")

return function(fabric)
	local deferredCreation

	fabric:on("unitRegistered", function(staticUnit)
		if staticUnit.isService == true then
			if deferredCreation == nil then
				deferredCreation = {}

				local connection

				connection = RunService.Heartbeat:Connect(function()
					connection:Disconnect()

					for _, staticUnitToCreate in ipairs(deferredCreation) do
						fabric:getOrCreateUnitByRef(staticUnitToCreate, game):mergeBaseLayer({})
					end

					deferredCreation = nil
				end)
			end

			table.insert(deferredCreation, staticUnit)
		end
	end)
end