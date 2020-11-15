local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Parent.Parent.Parent.Promise)
local FabricLib = require(script.Parent.Parent.Parent)
local Fabric = FabricLib.Fabric


return function()
	if not RunService:IsClient() then
		return
	end

	local testComponent, testRef


	-- TODO: since fabrics with the same namesapce share event listeners,
	-- we must use a unique namespace for each test
	local function makeFabric(namespace)
		local fabric = Fabric.new(namespace)
		FabricLib.useTags(fabric)
		FabricLib.useReplication(fabric)
		fabric:registerComponent(testComponent)
		return fabric
	end
	beforeEach(function()
		testComponent = {
			name = "TestTransmitter",
			components = {
				Replicated = {}
			},
		}
		testRef = script.Parent:WaitForChild("TEST_REF")
	end)

	describe("Transmitter", function()
		it("should transmit from client", function()
			local fabric = makeFabric("receive")
			local component = fabric:getOrCreateComponentByRef("TestTransmitter", testRef)
			expect(component).to.be.ok()
			component:getComponent("Transmitter"):send("TestEvent", "this is a test arg")
		end)

		it("should receive from server", function()
			local fabric = makeFabric("transmit")
			local component = fabric:getOrCreateComponentByRef("TestTransmitter", testRef)

			local done = false
			Promise.new(function(resolve)
				component:on("serverTestEvent", function(test_arg)
					print("RECV SERV EVENT", test_arg)
					resolve(test_arg == "this is a test arg")
				end)
			end):andThen(function(clientDone)
				done = clientDone
			end):timeout(2):await()
			expect(done).to.equal(true)
		end)

		it("should send with predictive layers", function()
			local fabric = makeFabric("predictive")
			local component = fabric:getOrCreateComponentByRef("TestTransmitter", testRef)
			expect(component).to.be.ok()
			component:mergeBaseLayer({
				someOtherData = true
			})
			component:getComponent("Transmitter"):sendWithPredictiveLayer({
				testData = true
			}, "TestEvent", "this is a test arg")
			-- on same frame, check if predictive data set
			expect(component:get("testData")).to.equal(true)
			local onRejectData = true
			Promise.new(function(resolve)
				component:getComponent("Transmitter"):on("rejectNetworkPrediction", function()
					onRejectData = component:get("testData")
					resolve()
				end)
			end):timeout(2):await()
			expect(onRejectData).to.never.be.ok()
		end)

		it("should send with valid predictive layers", function()
			local fabric = makeFabric("validPredictive")
			local component = fabric:getOrCreateComponentByRef("TestTransmitter", testRef)
			expect(component).to.be.ok()
			component:mergeBaseLayer({
				someOtherData = true
			})
			component:getComponent("Transmitter"):sendWithPredictiveLayer({
				testData = 1
			}, "TestEvent", "this is a test arg")
			-- on same frame, check if predictive data set
			expect(component:get("testData")).to.equal(1)
			Promise.new(function(resolve)
				component:on("serverResponse", function()
					print("RECV RSPONSE")
					resolve()
				end)
			end):timeout(5):await()
			expect(component:get("testData")).to.equal(2)
		end)
	end)
end