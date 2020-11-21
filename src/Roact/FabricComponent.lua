return function(fabric, roact)
		local FabricComponent = roact.Component:extend("FabricComponent")

		function FabricComponent:init()
				self.ref = roact.createRef()
		end

		function FabricComponent:render()
				local child = roact.oneChild(self.props[roact.Children])
				assert(not child, "FabricComponent cannot have any children!")
				assert(type(self.props.createRef) == "function", "FabricComponent requires a 'createRef' callback as a prop!")
				assert(self.props.units, "FabricComponent requires a 'units' table as a prop mapping component name -> base layer.")

				local rootCalled = false
				local createRoot = function(component, props, children)
						assert(rootCalled == false, "createRoot can only be called once!")
						props = props or {}
						rootCalled = true
						props[roact.Ref] = self.ref
						return roact.createElement(component, props, children)
				end

				local root = self.props.createRef(createRoot)

				return root
		end

		function FabricComponent:didMount()
			local ref = self.ref:getValue()
			assert(ref, "You must call createRoot in the passed createRef function!")
			for name, baseLayer in pairs(self.props.units) do
				local unit = fabric:getOrCreateUnitByRef(name, ref)
				unit:mergeBaseLayer(baseLayer)
			end
		end

		function FabricComponent:didUpdate()
			local ref = self.ref:getValue()
			assert(ref, "You must call createRoot in the passed createRef function!")
			for name, baseLayer in pairs(self.props.units) do
				local unit = fabric:getOrCreateUnitByRef(name, ref)
				unit:mergeBaseLayer(baseLayer)
			end
		end

		return FabricComponent
end