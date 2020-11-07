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
			onUpdated = function(self)
				callCounts:call("onUpdated")
			end;
			onLoaded = function(self)
				callCounts:call("onLoaded")
			end;
		}, callCounts
	end

	local fabric, callCounts, testComponent

	beforeEach(function()
		fabric = Fabric.new("test")

		testComponent, callCounts = makeTestComponentDefinition(fabric)

		fabric:registerComponent(testComponent)
	end)

	describe("Fabric", function()
		it("should add components", function()
			local pipeline = fabric:pipelineFor(TEST_REF, "foo")

			local component = pipeline:addLayer("Test", {
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

		describe("mergeWithBaseLayer", function()
			it("should allow merging into the base layer", function()
				local pipeline = fabric:pipelineFor(TEST_REF, "foo")

				pipeline:setBaseLayer("Test", {
					bar = 1
				})

				local component = fabric:getComponentByRef("Test", TEST_REF)

				component:mergeWithBaseLayer({
					foo = 2
				})
				expect(component.data.bar).to.equal(1)
				expect(component.data.foo).to.equal(2)

				component:mergeWithBaseLayer({
					bar = 2
				})
				expect(component.data.bar).to.equal(2)
				expect(component.data.foo).to.equal(2)
			end)

			it("should work when the base layer is nil", function()
				local component = fabric:getOrCreateComponentByRef("Test", TEST_REF)

				component:mergeWithBaseLayer({
					baz = 4
				})

				expect(component.data.baz).to.equal(4)
			end)

			it("should set fabric.None values to nil", function()
				local pipeline = fabric:pipelineFor(TEST_REF, "foo")

				pipeline:setBaseLayer("Test", {
					bar = 1
				})

				local component = fabric:getComponentByRef("Test", TEST_REF)

				expect(component.data.bar).to.equal(1)

				component:mergeWithBaseLayer({
					bar = fabric.None
				})
				expect(component.data.bar).to.never.be.ok()
			end)
		end)

		it("should combine layers", function()
			local pipeline = fabric:pipelineFor(TEST_REF, "foo")

			local component = pipeline:setBaseLayer("Test", {
				added = 1;
				nested = {
					value = "nested_value_first";
				};
				shouldUpdateTest = 1;
			})

			pipeline:getScope("bar"):addLayer("Test", {
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
			local pipeline = fabric:pipelineFor(TEST_REF, "foo")

			local component = pipeline:addLayer("Test", {
				shouldUpdateTest = 1;
			})

			pipeline:getScope("bar"):addLayer("Test", {
				shouldUpdateTest = 2;
			})

			expect(callCounts.shouldUpdate).to.equal(3)
			expect(callCounts.onUpdated).to.equal(1)
		end)

		it("should remove correctly", function()
			local pipeline = fabric:pipelineFor(TEST_REF, "foo")

			local component = pipeline:addLayer("Test", {
				added = 1;
			})

			local sameComponent = pipeline:getScope("bar"):addLayer("Test", {
				added = 2;
			})

			expect(component).to.equal(sameComponent)

			expect(component:get("added")).to.equal(3)

			pipeline:removeLayer("Test")

			expect(component:get("added")).to.equal(2)

			expect(component:isDestroyed()).to.equal(false)

			pipeline:getScope("bar"):removeLayer("Test")

			expect(component:get("added")).to.equal(nil)
			expect(callCounts.onDestroy).to.equal(1)
			expect(component:isDestroyed()).to.equal(true)

			local newComponent = pipeline:addLayer("Test", {
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

			local pipeline = fabric:pipelineFor(TEST_REF, "foo")
			local component = pipeline:addLayer("Test3", {})

			local otherPipeline = fabric:pipelineFor(TEST_REF_2, "foo")
			local otherComoponent = otherPipeline:addLayer("Test3", {})

			expect(component:isDestroyed()).to.equal(false)
			expect(otherComoponent:isDestroyed()).to.equal(false)

			pipeline:removeLayer("Test3")

			expect(component:isDestroyed()).to.equal(true)
			expect(otherComoponent:isDestroyed()).to.equal(false)
		end)
	end)
end