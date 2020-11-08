local Fabric = require(script.Parent)

return function()
	describe("Fabric.new", function()
		it("should return a fabric", function()
			local fabric = Fabric.new("the namespace")

			expect(fabric.namespace).to.equal("the namespace")
		end)
	end)

	describe("Fabric:registerComponent", function()
		it("should register components", function()
			local componentDef = {
				name = "Test";
			}
			local fabric = Fabric.new()

			local eventCount = 0

			fabric:on("componentRegistered", function()
				eventCount += 1
			end)

			fabric:registerComponent(componentDef)

			expect(fabric.Component.Test).to.be.ok()
			expect(eventCount).to.equal(1)
		end)

		it("shouldn't register duplicate components", function()
			local componentDef = {
				name = "Test";
			}
			local fabric = Fabric.new()

			fabric:registerComponent(componentDef)

			local componentDef2 = {
				name = "Test";
			}
			local stat, err = pcall(function()
				fabric:registerComponent(componentDef2)
			end)

			expect(stat).to.equal(false)
			expect(err:match("A component with this name is already registered!")).to.be.ok()
		end)
	end)

	describe("Fabric:registerComponentsIn", function()

	end)

	describe("Fabric:getComponentByRef and Fabric:getOrCreateComponentByRef", function()
		it("should create and get a component on ref", function()
			local componentDef = {
				name = "Test";
			}
			local fabric = Fabric.new()

			fabric:registerComponent(componentDef)

			local testRef = {}

			expect(fabric:getComponentByRef("Test", testRef)).to.never.be.ok()

			fabric:getOrCreateComponentByRef(componentDef, testRef)
			expect(fabric:getComponentByRef("Test", testRef)).to.be.ok()
		end)
	end)

	describe("Fabric:removeAllComponentsWithRef", function()
		it("should remove all components with a ref", function()
			local componentDef = {
				name = "Test";
			}
			local componentDef2 = {
				name = "Test2";
			}
			local fabric = Fabric.new()

			fabric:registerComponent(componentDef)
			fabric:registerComponent(componentDef2)

			local testRef = {}

			fabric:getOrCreateComponentByRef(componentDef, testRef)
			fabric:getOrCreateComponentByRef(componentDef2, testRef)

			expect(fabric:getComponentByRef("Test", testRef)).to.be.ok()
			expect(fabric:getComponentByRef("Test2", testRef)).to.be.ok()

			fabric:removeAllComponentsWithRef(testRef)

			expect(fabric:getComponentByRef("Test", testRef)).to.never.be.ok()
			expect(fabric:getComponentByRef("Test2", testRef)).to.never.be.ok()
		end)
	end)

	describe("Fabric:fire and Fabric:on", function()
		it("should fire events", function()
			local fabric = Fabric.new()

			local callCount = 0
			fabric:on("testEvent", function()
				callCount += 1
			end)

			expect(callCount).to.equal(0)

			fabric:fire("testEvent")

			expect(callCount).to.equal(1)

			fabric:fire("doesn't exist")

			expect(callCount).to.equal(1)
		end)
	end)
end