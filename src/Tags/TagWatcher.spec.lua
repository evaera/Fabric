local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local FabricLib = require(script.Parent.Parent)
local Fabric = FabricLib.Fabric

return function()
    local fabric, testInstance, invokeHeartbeat

	beforeEach(function()
		fabric = Fabric.new("tag watcher")
		FabricLib.useTags(fabric)
		do
			-- monkey patch heartbeat
			local heartbeatBindableEvent = Instance.new("BindableEvent")
			fabric.Heartbeat = heartbeatBindableEvent.Event
			invokeHeartbeat = function(...)
				heartbeatBindableEvent:Fire(...)
			end
		end

		testInstance = Instance.new("Part")
		testInstance.Parent = Workspace
    end)

    afterEach(function()
		testInstance:Destroy()
    end)

    it("shouldn't listen before registering", function()
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
        fabric:registerUnit(newUnit2)
        CollectionService:AddTag(testInstance, "Test3")
        expect(CollectionService:HasTag(testInstance, "Test3")).to.equal(true)
        fabric:registerUnit(newUnit)
        invokeHeartbeat()
        local unit = fabric:getUnitByRef("Test3", testInstance)
        expect(unit).to.be.ok()
        expect(fabric:getUnitByRef("Test2", unit)).to.be.ok()
    end)
end