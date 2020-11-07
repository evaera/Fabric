local Component = require(script.Parent.Fabric.Component)

return function(fabric, roact)
	local roactComponent = require(script.FabricComponent)(fabric, roact)

	local function createElement(instance, props, children)
		local componentProps = {}

		if props then
			for key, value in pairs(props) do
				if getmetatable(key) == Component then
					componentProps[key] = value
					props[key] = nil
				end
			end
		end

		if next(componentProps) then
			-- we create a roactComponent to attach fabric components to the instance
			return roact.createElement(roactComponent, {
				components = componentProps,
				createRef = function(root)
					return root(instance, props, children)
				end
			})
		else
			return roact.createElement(instance, props, children)
		end
	end

	local function setupRender(staticComponent)
		if staticComponent.render then
			local effects = staticComponent.effects or {}

			table.insert(effects, function(self)
					local rootElement = staticComponent.render(self, createElement)

					if rootElement == nil and self._roactHandle then
						roact.unmount(self._roactHandle)
						self._roactHandle = nil
						return
					end

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