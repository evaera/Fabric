return function(fabric, roact)
		local FabricUnit = roact.Unit:extend("FabricUnit")

		function FabricUnit:init()
				self.ref = roact.createRef()
		end

		function FabricUnit:render()
				local child = roact.oneChild(self.props[roact.Children])
				assert(not child, "FabricUnit cannot have any children!")
				assert(type(self.props.createRef) == "function", "FabricUnit requires a 'createRef' callback as a prop!")
				assert(self.props.units, "FabricUnit requires a 'units' table as a prop mapping unit name -> base layer.")

				local rootCalled = false
				local createRoot = function(unit, props, children)
						assert(rootCalled == false, "createRoot can only be called once!")
						props = props or {}
						rootCalled = true
						props[roact.Ref] = self.ref
						return roact.createElement(unit, props, children)
				end

				local root = self.props.createRef(createRoot)

				return root
		end

		function FabricUnit:didMount()
			local ref = self.ref:getValue()
			assert(ref, "You must call createRoot in the passed createRef function!")
			for name, baseLayer in pairs(self.props.units) do
				local unit = fabric:getOrCreateUnitByRef(name, ref)
				unit:mergeBaseLayer(baseLayer)
			end
		end

		function FabricUnit:didUpdate()
			local ref = self.ref:getValue()
			assert(ref, "You must call createRoot in the passed createRef function!")
			for name, baseLayer in pairs(self.props.units) do
				local unit = fabric:getOrCreateUnitByRef(name, ref)
				unit:mergeBaseLayer(baseLayer)
			end
		end

		return FabricUnit
end