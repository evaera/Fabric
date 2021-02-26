local Util = require(script.Parent.Parent.Shared.Util)
local Fabric = require(script.Parent)

local TEST_REF = {}
local TEST_REF_2 = {}

return function()
	local function makeTestUnitDefinition(fabric)
		local callCounts =  Util.callCounter()

		local reducers = fabric.reducers

		return {
			name = "Test";
			onInitialize = function(self)
				expect(self).to.be.ok()
				callCounts:call("onInitialize")
			end;
			onDestroy = function(self)
				expect(self).to.be.ok()
				callCounts:call("onDestroy")
			end;
			defaults = {
				testDefault = 5;
			};
			reducer = reducers.structure({
				added = reducers.add;
				nested = reducers.structure({
					value = reducers.last;
				})
			});
			shouldUpdate = fabric.comparators.structure({
				shouldUpdateTest = function()
					callCounts:call("shouldUpdate")
					return false
				end
			});
			schema = function(data)
				expect(data).to.be.ok()
				expect(type(data)).to.equal("table")

				callCounts:call("schema")

				return true
			end;
			refCheck = function(ref)
				expect(ref).to.be.ok()
				expect(ref).to.equal(TEST_REF)
				callCounts:call("refCheck")

				return true
			end;
			tag = "Test";
			onUpdated = function()
				callCounts:call("onUpdated")
			end;
			onLoaded = function()
				callCounts:call("onLoaded")
			end;
		}, callCounts
	end

	local fabric

	beforeEach(function()
		fabric = Fabric.new("test")
	end)

	describe("Unit", function()
		it("should add units", function()
			local testUnit, callCounts = makeTestUnitDefinition(fabric)
			fabric:registerUnit(testUnit)

			local unit = fabric:getOrCreateUnitByRef("Test", TEST_REF)

			unit:addLayer("foo", {
				added = 1;
				nested = {
					value = "nested_value";
				};
				shouldUpdateTest = 1;
			})

			expect(callCounts.refCheck).to.equal(1)
			expect(callCounts.onInitialize).to.equal(1)
			expect(unit:isLoaded()).to.equal(true)
			expect(callCounts.onLoaded).to.equal(1)
			expect(callCounts.onUpdated).to.equal(1)
			expect(callCounts.schema).to.equal(1)
			expect(callCounts.onDestroy).to.equal(0)

			local loadedPromise = fabric:getLoadedUnitByRef("Test", TEST_REF)
			expect(loadedPromise:getStatus()).to.equal("Resolved")
			expect(loadedPromise._values[1]).to.equal(unit)

			expect(unit:get("added")).to.equal(1)
			expect(unit:get("testDefault")).to.equal(5)
			expect(unit:get({"nested", "value"})).to.equal("nested_value")
		end)

		it("should have data and lastData correct in onUpdated", function()
			local iteration = 0
			local callCount = 0

			fabric:registerUnit({
				name = "hi";
				onUpdated = function(self, newData, lastData)
					callCount += 1

					if iteration == 0 then
						expect(newData).to.be.ok()
						expect(lastData).to.never.be.ok()

						expect(newData.foo).to.equal(1)
					elseif iteration == 1 then
						expect(newData).to.be.ok()
						expect(lastData).to.be.ok()

						expect(newData.foo).to.equal(2)
						expect(lastData.foo).to.equal(1)
					end
				end
			})

			expect(callCount).to.equal(0)

			local unit = fabric:getOrCreateUnitByRef("hi", TEST_REF)

			unit:addLayer("hi", {
				foo = 1
			})

			expect(callCount).to.equal(1)

			iteration += 1

			unit:addLayer("hi", {
				foo = 2
			})

			expect(callCount).to.equal(2)
		end)

		it("should be safe when dealing with non-table data", function()
			fabric:registerUnit({
				name = "foo",
				reducer = fabric.reducers.add,
				defaults = {
					bar = 2
				}
			})

			local unit = fabric:getOrCreateUnitByRef("foo", TEST_REF)

			unit:addLayer("aaa", 1)

			expect(unit:get()).to.equal(1)
		end)

		describe("mergeBaseLayer", function()
			it("should allow merging into the base layer", function()
				local testUnit, _callCounts = makeTestUnitDefinition(fabric)
				fabric:registerUnit(testUnit)
				local unit = fabric:getOrCreateUnitByRef("Test", TEST_REF)

				unit:mergeBaseLayer({
					bar = 1
				})

				unit:mergeBaseLayer({
					foo = 2
				})
				expect(unit.data.bar).to.equal(1)
				expect(unit.data.foo).to.equal(2)

				unit:mergeBaseLayer({
					bar = 2
				})
				expect(unit.data.bar).to.equal(2)
				expect(unit.data.foo).to.equal(2)
			end)

			it("should work when the base layer is nil", function()
				local testUnit, _callCounts = makeTestUnitDefinition(fabric)
				fabric:registerUnit(testUnit)

				local unit = fabric:getOrCreateUnitByRef("Test", TEST_REF)

				unit:mergeBaseLayer({
					baz = 4
				})

				expect(unit.data.baz).to.equal(4)
			end)

			it("should set fabric.None values to nil", function()
				local testUnit, _callCounts = makeTestUnitDefinition(fabric)
				fabric:registerUnit(testUnit)

				local unit = fabric:getOrCreateUnitByRef("Test", TEST_REF)

				unit:mergeBaseLayer({
					bar = 1
				})

				expect(unit.data.bar).to.equal(1)

				unit:mergeBaseLayer({
					bar = fabric.None
				})
				expect(unit.data.bar).to.never.be.ok()
			end)
		end)

		describe("get", function()
			it("should get values", function()
				fabric:registerUnit({
					name = "foo"
				})

				local unit = fabric:getOrCreateUnitByRef("foo", TEST_REF)

				expect(unit:get("baz")).to.equal(nil)
				expect(unit:get({})).to.equal(nil)

				unit:addLayer("bar", {
					baz = 1
				})

				expect(unit:get("baz")).to.equal(1)
				expect(unit:get({"baz"})).to.equal(1)

				expect(unit:get().baz).to.equal(1)
				expect(unit:get({}).baz).to.equal(1)
			end)

			it("should get nested values", function()
				fabric:registerUnit({
					name = "foo"
				})

				local unit = fabric:getOrCreateUnitByRef("foo", TEST_REF)

				expect(unit:get("baz")).to.equal(nil)

				unit:addLayer("bar", {
					baz = {
						qux = 1
					}
				})

				expect(unit:get({"baz", "qux"})).to.equal(1)

				expect(unit:get().baz.qux).to.equal(1)
				expect(unit:get({"baz"}).qux).to.equal(1)
			end)

			it("should error with non-table data", function()
				fabric:registerUnit({
					name = "foo",
					reducer = fabric.reducers.add,
				})

				local unit = fabric:getOrCreateUnitByRef("foo", TEST_REF)

				expect(unit:get("baz")).to.equal(nil)
				expect(unit:get({})).to.equal(nil)

				unit:addLayer("bar", 1)

				expect(function()
					unit:get("bad")
				end).to.throw()

				expect(function()
					unit:get({"hi"})
				end).to.throw()

				expect(unit:get()).to.equal(1)
				expect(unit:get({})).to.equal(1)
			end)
		end)

		it("should combine layers", function()
			local testUnit, callCounts = makeTestUnitDefinition(fabric)
			fabric:registerUnit(testUnit)

			local unit = fabric:getOrCreateUnitByRef("Test", TEST_REF)
			unit:mergeBaseLayer({
				added = 1;
				nested = {
					value = "nested_value_first";
				};
				shouldUpdateTest = 1;
			})

			unit:addLayer("bar", {
				added = 1;
				nested = {
					value = "nested_value_last";
				};
				shouldUpdateTest = 2;
			})

			expect(callCounts.refCheck).to.equal(1)
			expect(callCounts.onInitialize).to.equal(1)
			expect(callCounts.onLoaded).to.equal(1)
			expect(callCounts.onUpdated).to.equal(2)
			expect(callCounts.schema).to.equal(2)
			expect(callCounts.onDestroy).to.equal(0)

			expect(unit:get("added")).to.equal(2)
			expect(unit:get({"nested", "value"})).to.equal("nested_value_last")
		end)

		it("should run the shouldUpdate handler", function()
			local testUnit, callCounts = makeTestUnitDefinition(fabric)
			fabric:registerUnit(testUnit)

			local unit = fabric:getOrCreateUnitByRef("Test", TEST_REF)
			unit:addLayer("foo", {
				shouldUpdateTest = 1;
			})

			unit:addLayer("bar", {
				shouldUpdateTest = 2;
			})

			expect(callCounts.shouldUpdate).to.equal(3)
			expect(callCounts.onUpdated).to.equal(1)
		end)

		it("should remove correctly", function()
			local testUnit, callCounts = makeTestUnitDefinition(fabric)
			fabric:registerUnit(testUnit)

			local unit = fabric:getOrCreateUnitByRef("Test", TEST_REF)

			unit:addLayer("foo", {
				added = 1;
			})

			unit:addLayer("bar", {
				added = 2;
			})

			expect(unit:get("added")).to.equal(3)

			unit:removeLayer("foo")

			expect(unit:get("added")).to.equal(2)

			expect(unit:isDestroyed()).to.equal(false)

			unit:removeLayer("bar")

			expect(unit:get("added")).to.equal(nil)
			expect(callCounts.onDestroy).to.equal(1)
			expect(unit:isDestroyed()).to.equal(true)

			local newUnit = fabric:getOrCreateUnitByRef("Test", TEST_REF)
			newUnit:addLayer("foo", {
				added = 1;
			})

			expect(newUnit).to.never.equal(unit)
		end)

		it("shouldn't remove other refs", function()
			local newUnit = {
				name = "Test2",
				tag = "Test2",
			}
			local newUnit2 = {
				name = "Test3",
				tag = "Test3",
				units = {
					Test2 = {}
				},
			}
			fabric:registerUnit(newUnit)
			fabric:registerUnit(newUnit2)

			local unit = fabric:getOrCreateUnitByRef("Test3", TEST_REF)
			unit:addLayer("foo", {})
			local otherUnit = fabric:getOrCreateUnitByRef("Test3", TEST_REF_2)
			otherUnit:addLayer("foo", {})

			expect(unit:isDestroyed()).to.equal(false)
			expect(otherUnit:isDestroyed()).to.equal(false)

			unit:removeLayer("foo")

			expect(unit:isDestroyed()).to.equal(true)
			expect(otherUnit:isDestroyed()).to.equal(false)
		end)

		it("should attach nested units", function()
			local newUnit = {
				name = "Test2",
				tag = "Test2",
			}
			local newUnit2 = {
				name = "Test3",
				tag = "Test3",
				units = {
					Test2 = {
						foo = 1;
					}
				},
			}
			fabric:registerUnit(newUnit)
			fabric:registerUnit(newUnit2)

			local unit = fabric:getOrCreateUnitByRef("Test3", TEST_REF)
			local nestedUnit = unit:getUnit("Test2")

			expect(unit).to.be.ok()
			expect(nestedUnit).to.be.ok()
			expect(nestedUnit.data.foo).to.equal(1)
		end)

		it("should remove layers whose scopes are units when the unit is destroyed", function()
			fabric:registerUnit({
				name = "Test"
			})

			local unit = fabric:getOrCreateUnitByRef("Test", TEST_REF)
			local unitToBeRemoved = fabric:getOrCreateUnitByRef("Test", TEST_REF_2)

			unit:addLayer("some scope", {
				foo = 0
			})

			expect(unit:get("foo")).to.equal(0)

			unit:addLayer(unitToBeRemoved, {
				foo = 1
			})

			expect(unit:get("foo")).to.equal(1)

			expect(unit:isDestroyed()).to.equal(false)
			expect(unitToBeRemoved:isDestroyed()).to.equal(false)

			fabric:removeAllUnitsWithRef(TEST_REF_2)

			expect(unit:isDestroyed()).to.equal(false)
			expect(unit:get("foo")).to.equal(0)
		end)
	end)
	describe("Events", function()
		SKIP()
		it("shouldn't run events if connected during firing", function()
			fabric:registerUnit({
				name = "Test",
			})

			local unit = fabric:getOrCreateUnitByRef("Test", TEST_REF)

			local count = 0
			unit:on("foo", function()
				unit:on("foo", function()
					count += 1
				end)
			end)

			unit:fire("foo")

			expect(count).to.equal(0)
		end)

		it("shouldn't skip events if one is disconnected during firing", function()
			fabric:registerUnit({
				name = "Test",
			})

			local unit = fabric:getOrCreateUnitByRef("Test", TEST_REF)

			local disconnect
			disconnect = unit:on("foo", function()
				disconnect()
			end)

			local count = 0
			unit:on("foo", function()
				count += 1
			end)

			expect(count).to.equal(1)
		end)
	end)
end