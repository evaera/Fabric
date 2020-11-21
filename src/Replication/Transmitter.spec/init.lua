local Players = game:GetService("Players")
local FabricLib = require(script.Parent.Parent)
local Fabric = FabricLib.Fabric
local Promise = require(script.Parent.Parent.Parent.Promise)
local invokeClientRPC = require(script.Parent.Parent.Shared.ClientTestRPC)
-- TEST_REF must be visible to clients
local TEST_REF = Instance.new("Folder")
TEST_REF.Name = "TEST_REF"
TEST_REF.Parent = script

return function()

	-- HACK: Detect if play solo (devhub big dumb dumb https://developer.roblox.com/en-us/api-reference/function/RunService/IsRunMode)
	wait(1)
	if #Players:GetPlayers() == 0 then
		return
	end


	local testUnit

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
	end)

	describe("Transmitter", function()
		it("should receive from client", function()
			local fabric = makeFabric("receive")
			local unit = fabric:getOrCreateUnitByRef("TestTransmitter", TEST_REF)
			expect(unit).to.be.ok()

			local done = false
			local promise = Promise.new(function(resolve)
				unit:on("clientTestEvent", function(_, test_arg)
					resolve(test_arg == "this is a test arg")
				end)
			end):andThen(function(serverDone)
				done = serverDone
			end)

			invokeClientRPC("invoke_test", {script["TransmitterClient.spec"]}, nil, {testNamePattern = "should transmit from client"})

			promise:timeout(2):await()
			expect(done).to.equal(true)
		end)

		it("should transmit to client", function()
			local fabric = makeFabric("transmit")
			local unit = fabric:getOrCreateUnitByRef("TestTransmitter", TEST_REF)
			expect(unit).to.be.ok()

			-- wait for client to sub before pub
			Promise.all({
				Promise.new(function(resolve)
					resolve(invokeClientRPC("invoke_test", {script["TransmitterClient.spec"]}, nil, {testNamePattern = "should receive from server"}))
				end),
				Promise.new(function(resolve)
					unit:getUnit("Transmitter"):on("subscriberAdded", function()
						resolve(unit:getUnit("Transmitter"):broadcast("TestEvent", "this is a test arg"))
					end)
				end)
			}):timeout(2):await()
		end)

		it("should reject invalid predictive layers", function()
			local fabric = makeFabric("predictive")
			local unit = fabric:getOrCreateUnitByRef("TestTransmitter", TEST_REF)
			expect(unit).to.be.ok()
			local done = false
			local promise = Promise.new(function(resolve)
				unit:on("clientTestEvent", function(_, test_arg)
					resolve(test_arg == "this is a test arg")
				end)
			end):andThen(function(serverDone)
				done = serverDone
			end)

			invokeClientRPC("invoke_test", {script["TransmitterClient.spec"]}, nil, {testNamePattern = "should send with predictive layers"})

			promise:timeout(2):await()
			expect(done).to.equal(true)
		end)

		it("should respond to valid predictive layer", function()
			local fabric = makeFabric("validPredictive")
			local unit = fabric:getOrCreateUnitByRef("TestTransmitter", TEST_REF)
			expect(unit).to.be.ok()

			local done = false
			Promise.all({
				Promise.new(function(resolve)
					unit:on("clientTestEvent", function(_, test_arg)
						resolve(test_arg == "this is a test arg")
					end)
				end):andThen(function(serverDone)
					done = serverDone
					unit:mergeBaseLayer({
						testData = 2
					})
					unit:getUnit("Transmitter"):broadcast("Response")
				end),
				Promise.new(function(resolve)
					invokeClientRPC("invoke_test", {script["TransmitterClient.spec"]}, nil, {testNamePattern = "should send with valid predictive layers"})
					resolve()
				end)
			}):timeout(2):await()

			expect(done).to.equal(true)
		end)
	end)
end