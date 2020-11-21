local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Parent.Parent.Parent.Promise)
local FabricLib = require(script.Parent.Parent.Parent)
local Fabric = FabricLib.Fabric


return function()
	if not RunService:IsClient() then
		return
	end

	local testUnit, testRef


	-- TODO: since fabrics with the same namesapce share event listeners,
	-- we must use a unique namespace for each test
	local function makeFabric(namespace)
		local fabric = Fabric.new(namespace)
		FabricLib.useTags(fabric)
		FabricLib.useReplication(fabric)
		fabric:registerUnit(testUnit)
		return fabric
	end
	beforeEach(function()
		testUnit = {
			name = "TestTransmitter",
			units = {
				Replicated = {}
			},
		}
		testRef = script.Parent:WaitForChild("TEST_REF")
	end)

	describe("Transmitter", function()
		it("should transmit from client", function()
			local fabric = makeFabric("receive")
			local unit = fabric:getOrCreateUnitByRef("TestTransmitter", testRef)
			expect(unit).to.be.ok()
			unit:getUnit("Transmitter"):send("TestEvent", "this is a test arg")
		end)

		it("should receive from server", function()
			local fabric = makeFabric("transmit")
			local unit = fabric:getOrCreateUnitByRef("TestTransmitter", testRef)

			local done = false
			Promise.new(function(resolve)
				unit:on("serverTestEvent", function(test_arg)
					resolve(test_arg == "this is a test arg")
				end)
			end):andThen(function(clientDone)
				done = clientDone
			end):timeout(2):await()
			expect(done).to.equal(true)
		end)

		it("should send with predictive layers", function()
			local fabric = makeFabric("predictive")
			local unit = fabric:getOrCreateUnitByRef("TestTransmitter", testRef)
			expect(unit).to.be.ok()
			unit:mergeBaseLayer({
				someOtherData = true
			})
			unit:getUnit("Transmitter"):sendWithPredictiveLayer({
				testData = true
			}, "TestEvent", "this is a test arg")
			-- on same frame, check if predictive data set
			expect(unit:get("testData")).to.equal(true)
			local onRejectData = true
			Promise.new(function(resolve)
				unit:getUnit("Transmitter"):on("rejectNetworkPrediction", function()
					onRejectData = unit:get("testData")
					resolve()
				end)
			end):timeout(2):await()
			expect(onRejectData).to.never.be.ok()
		end)

		it("should send with valid predictive layers", function()
			local fabric = makeFabric("validPredictive")
			local unit = fabric:getOrCreateUnitByRef("TestTransmitter", testRef)
			expect(unit).to.be.ok()
			unit:mergeBaseLayer({
				someOtherData = true
			})
			unit:getUnit("Transmitter"):sendWithPredictiveLayer({
				testData = 1
			}, "TestEvent", "this is a test arg")
			-- on same frame, check if predictive data set
			expect(unit:get("testData")).to.equal(1)
			Promise.new(function(resolve)
				unit:on("serverResponse", function()
					resolve()
				end)
			end):timeout(5):await()
			expect(unit:get("testData")).to.equal(2)
		end)
	end)
end