local Unit = require(script.Parent.Fabric.Unit)

return function(fabric, roact)
	local roactUnit = require(script.FabricUnit)(fabric, roact)

	local function createElement(instance, props, children)
		local unitProps = {}

		if props then
			for key, value in pairs(props) do
				if getmetatable(key) == Unit then
					unitProps[key] = value
					props[key] = nil
				end
			end
		end

		if next(unitProps) then
			-- we create a roactUnit to attach fabric units to the instance
			return roact.createElement(roactUnit, {
				units = unitProps,
				createRef = function(root)
					return root(instance, props, children)
				end
			})
		else
			return roact.createElement(instance, props, children)
		end
	end

	local function setupRender(staticUnit)
		if staticUnit.render then
			local effects = staticUnit.effects or {}

			effects._roactRender = function(self)
					local rootElement = staticUnit.render(self, createElement)

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
			end

		end
	end

	fabric:on("unitRegistered", setupRender)
	fabric:on("unitHotReloaded", setupRender)
end