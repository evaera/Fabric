return function(fabric, roact)
	local function setupRender(staticComponent)
		if staticComponent.render then
			local effects = staticComponent.effects or {}

			table.insert(effects, function(self)
					local rootElement = staticComponent.render(self, roact.createElement)

					if self._roactHandle == nil then
						self._roactHandle = roact.mount(rootElement, self.ref)

						self:on("destroy", function()
							roact.unmount(self._roactHandle)
							self._roactHandle = nil
						end)
					else
						roact.update(self._roactHandle, rootElement)
					end
			end)
		end
	end

	fabric:on("componentRegistered", setupRender)
	fabric:on("componentHotReloaded", setupRender)

end