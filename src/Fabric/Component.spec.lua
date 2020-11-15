local Util = require(script.Parent.Parent.Shared.Util)
local Fabric = require(script.Parent)

local TEST_REF = {}
local TEST_REF_2 = {}

return function()
	local function makeTestComponentDefinition(fabric)
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

	describe("Component", function()
		it("should add components", function()
			local testComponent, callCounts = makeTestComponentDefinition(fabric)
			fabric:registerComponent(testComponent)

			local component = fabric:getOrCreateComponentByRef("Test", TEST_REF)

			component:addLayer("foo", {
				added = 1;
				nested = {
					value = "nested_value";
				};
				shouldUpdateTest = 1;
			})

			expect(callCounts.refCheck).to.equal(1)
			expect(callCounts.onInitialize).to.equal(1)
			expect(component:isLoaded()).to.equal(true)
			expect(callCounts.onLoaded).to.equal(1)
			expect(callCounts.onUpdated).to.equal(1)
			expect(callCounts.schema).to.equal(1)
			expect(callCounts.onDestroy).to.equal(0)

			local loadedPromise = fabric:getLoadedComponentByRef("Test", TEST_REF)
			expect(loadedPromise:getStatus()).to.equal("Resolved")
			expect(loadedPromise._values[1]).to.equal(component)

			expect(component:get("added")).to.equal(1)
			expect(component:get("testDefault")).to.equal(5)
			expect(component:get({"nested", "value"})).to.equal("nested_value")
		end)

		it("should have data and lastData correct in onUpdated", function()
			local iteration = 0
			local callCount = 0

			fabric:registerComponent({
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

			local component = fabric:getOrCreateComponentByRef("hi", TEST_REF)

			component:addLayer("hi", {
				foo = 1
			})

			expect(callCount).to.equal(1)

			iteration += 1

			component:addLayer("hi", {
				foo = 2
			})

			expect(callCount).to.equal(2)
		end)

		describe("mergeBaseLayer", function()
			it("should allow merging into the base layer", function()
				local testComponent, _callCounts = makeTestComponentDefinition(fabric)
				fabric:registerComponent(testComponent)
				local component = fabric:getOrCreateComponentByRef("Test", TEST_REF)

				component:mergeBaseLayer({
					bar = 1
				})

				component:mergeBaseLayer({
					foo = 2
				})
				expect(component.data.bar).to.equal(1)
				expect(component.data.foo).to.equal(2)

				component:mergeBaseLayer({
					bar = 2
				})
				expect(component.data.bar).to.equal(2)
				expect(component.data.foo).to.equal(2)
			end)

			it("should work when the base layer is nil", function()
				local testComponent, _callCounts = makeTestComponentDefinition(fabric)
				fabric:registerComponent(testComponent)

				local component = fabric:getOrCreateComponentByRef("Test", TEST_REF)

				component:mergeBaseLayer({
					baz = 4
				})

				expect(component.data.baz).to.equal(4)
			end)

			it("should set fabric.None values to nil", function()
				local testComponent, _callCounts = makeTestComponentDefinition(fabric)
				fabric:registerComponent(testComponent)

				local component = fabric:getOrCreateComponentByRef("Test", TEST_REF)

				component:mergeBaseLayer({
					bar = 1
				})

				expect(component.data.bar).to.equal(1)

				component:mergeBaseLayer({
					bar = fabric.None
				})
				expect(component.data.bar).to.never.be.ok()
			end)
		end)

		describe("get", function()
			it("should get values", function()
				fabric:registerComponent({
					name = "foo"
				})

				local component = fabric:getOrCreateComponentByRef("foo", TEST_REF)

				expect(component:get("baz")).to.equal(nil)
				expect(component:get({})).to.equal(nil)

				component:addLayer("bar", {
					baz = 1
				})

				expect(component:get("baz")).to.equal(1)
				expect(component:get({"baz"})).to.equal(1)

				expect(component:get().baz).to.equal(1)
				expect(component:get({}).baz).to.equal(1)
			end)

			it("should get nested values", function()
				fabric:registerComponent({
					name = "foo"
				})

				local component = fabric:getOrCreateComponentByRef("foo", TEST_REF)

				expect(component:get("baz")).to.equal(nil)

				component:addLayer("bar", {
					baz = {
						qux = 1
					}
				})

				expect(component:get({"baz", "qux"})).to.equal(1)

				expect(component:get().baz.qux).to.equal(1)
				expect(component:get({"baz"}).qux).to.equal(1)
			end)

			it("should error with non-table data", function()
				fabric:registerComponent({
					name = "foo",
					reducer = fabric.reducers.add,
				})

				local component = fabric:getOrCreateComponentByRef("foo", TEST_REF)

				expect(component:get("baz")).to.equal(nil)
				expect(component:get({})).to.equal(nil)

				component:addLayer("bar", 1)

				expect(function()
					component:get("bad")
				end).to.throw()

				expect(function()
					component:get({"hi"})
				end).to.throw()

				expect(component:get()).to.equal(1)
				expect(component:get({})).to.equal(1)
			end)
		end)

		it("should combine layers", function()
			local testComponent, callCounts = makeTestComponentDefinition(fabric)
			fabric:registerComponent(testComponent)

			local component = fabric:getOrCreateComponentByRef("Test", TEST_REF)
			component:mergeBaseLayer({
				added = 1;
				nested = {
					value = "nested_value_first";
				};
				shouldUpdateTest = 1;
			})

			component:addLayer("bar", {
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

			expect(component:get("added")).to.equal(2)
			expect(component:get({"nested", "value"})).to.equal("nested_value_last")
		end)

		it("should run the shouldUpdate handler", function()
			local testComponent, callCounts = makeTestComponentDefinition(fabric)
			fabric:registerComponent(testComponent)

			local component = fabric:getOrCreateComponentByRef("Test", TEST_REF)
			component:addLayer("foo", {
				shouldUpdateTest = 1;
			})

			component:addLayer("bar", {
				shouldUpdateTest = 2;
			})

			expect(callCounts.shouldUpdate).to.equal(3)
			expect(callCounts.onUpdated).to.equal(1)
		end)

		it("should remove correctly", function()
			local testComponent, callCounts = makeTestComponentDefinition(fabric)
			fabric:registerComponent(testComponent)

			local component = fabric:getOrCreateComponentByRef("Test", TEST_REF)

			component:addLayer("foo", {
				added = 1;
			})

			component:addLayer("bar", {
				added = 2;
			})

			expect(component:get("added")).to.equal(3)

			component:removeLayer("foo")

			expect(component:get("added")).to.equal(2)

			expect(component:isDestroyed()).to.equal(false)

			component:removeLayer("bar")

			expect(component:get("added")).to.equal(nil)
			expect(callCounts.onDestroy).to.equal(1)
			expect(component:isDestroyed()).to.equal(true)

			local newComponent = fabric:getOrCreateComponentByRef("Test", TEST_REF)
			newComponent:addLayer("foo", {
				added = 1;
			})

			expect(newComponent).to.never.equal(component)
		end)

		it("shouldn't remove other refs", function()
			local newComponent = {
				name = "Test2",
				tag = "Test2",
			}
			local newComponent2 = {
				name = "Test3",
				tag = "Test3",
				components = {
					Test2 = {}
				},
			}
			fabric:registerComponent(newComponent)
			fabric:registerComponent(newComponent2)

			local component = fabric:getOrCreateComponentByRef("Test3", TEST_REF)
			component:addLayer("foo", {})
			local otherComponent = fabric:getOrCreateComponentByRef("Test3", TEST_REF_2)
			otherComponent:addLayer("foo", {})

			expect(component:isDestroyed()).to.equal(false)
			expect(otherComponent:isDestroyed()).to.equal(false)

			component:removeLayer("foo")

			expect(component:isDestroyed()).to.equal(true)
			expect(otherComponent:isDestroyed()).to.equal(false)
		end)

		it("should attach nested components", function()
			local newComponent = {
				name = "Test2",
				tag = "Test2",
			}
			local newComponent2 = {
				name = "Test3",
				tag = "Test3",
				components = {
					Test2 = {
						foo = 1;
					}
				},
			}
			fabric:registerComponent(newComponent)
			fabric:registerComponent(newComponent2)

			local component = fabric:getOrCreateComponentByRef("Test3", TEST_REF)
			local nestedComponent = component:getComponent("Test2")

			expect(component).to.be.ok()
			expect(nestedComponent).to.be.ok()
			expect(nestedComponent.data.foo).to.equal(1)
		end)

		it("should remove layers whose scopes are components when the component is destroyed", function()
			fabric:registerComponent({
				name = "Test"
			})

			local component = fabric:getOrCreateComponentByRef("Test", TEST_REF)
			local componentToBeRemoved = fabric:getOrCreateComponentByRef("Test", TEST_REF_2)

			component:addLayer("some scope", {
				foo = 0
			})

			expect(component:get("foo")).to.equal(0)

			component:addLayer(componentToBeRemoved, {
				foo = 1
			})

			expect(component:get("foo")).to.equal(1)

			expect(component:isDestroyed()).to.equal(false)
			expect(componentToBeRemoved:isDestroyed()).to.equal(false)

			fabric:removeAllComponentsWithRef(TEST_REF_2)

			expect(component:isDestroyed()).to.equal(false)
			expect(component:get("foo")).to.equal(0)
		end)
	end)
end