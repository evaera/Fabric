local Fabric = require(script.Parent)

return function()
	describe("Fabric.new", function()
		it("should return a fabric", function()
			local fabric = Fabric.new("the namespace")

			expect(fabric.namespace).to.equal("the namespace")
		end)
	end)

	describe("Fabric:registerUnit", function()
		it("should register units", function()
			local unitDef = {
				name = "Test";
			}
			local fabric = Fabric.new()

			local eventCount = 0

			fabric:on("unitRegistered", function()
				eventCount += 1
			end)

			fabric:registerUnit(unitDef)

			expect(fabric.Unit.Test).to.be.ok()
			expect(eventCount).to.equal(1)
		end)

		it("shouldn't register duplicate units", function()
			local unitDef = {
				name = "Test";
			}
			local fabric = Fabric.new()

			fabric:registerUnit(unitDef)

			local unitDef2 = {
				name = "Test";
			}
			local stat, err = pcall(function()
				fabric:registerUnit(unitDef2)
			end)

			expect(stat).to.equal(false)
			expect(err:match("A unit with this name is already registered!")).to.be.ok()
		end)
	end)

	describe("Fabric:registerUnitsIn", function()

	end)

	describe("Fabric:getUnitByRef and Fabric:getOrCreateUnitByRef", function()
		it("should create and get a unit on ref", function()
			local unitDef = {
				name = "Test";
			}
			local fabric = Fabric.new()

			fabric:registerUnit(unitDef)

			local testRef = {}

			expect(fabric:getUnitByRef("Test", testRef)).to.never.be.ok()

			fabric:getOrCreateUnitByRef(unitDef, testRef)
			expect(fabric:getUnitByRef("Test", testRef)).to.be.ok()
		end)
	end)

	describe("Fabric:removeAllUnitsWithRef", function()
		it("should remove all units with a ref", function()
			local unitDef = {
				name = "Test";
			}
			local unitDef2 = {
				name = "Test2";
			}
			local fabric = Fabric.new()

			fabric:registerUnit(unitDef)
			fabric:registerUnit(unitDef2)

			local testRef = {}

			fabric:getOrCreateUnitByRef(unitDef, testRef)
			fabric:getOrCreateUnitByRef(unitDef2, testRef)

			expect(fabric:getUnitByRef("Test", testRef)).to.be.ok()
			expect(fabric:getUnitByRef("Test2", testRef)).to.be.ok()

			fabric:removeAllUnitsWithRef(testRef)

			expect(fabric:getUnitByRef("Test", testRef)).to.never.be.ok()
			expect(fabric:getUnitByRef("Test2", testRef)).to.never.be.ok()
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