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
        fabric:registerComponent(newComponent2)
        CollectionService:AddTag(testInstance, "Test3")
        expect(CollectionService:HasTag(testInstance, "Test3")).to.equal(true)
        fabric:registerComponent(newComponent)
        invokeHeartbeat()
        local component = fabric:getComponentByRef("Test3", testInstance)
        expect(component).to.be.ok()
        expect(fabric:getComponentByRef("Test2", component)).to.be.ok()
    end)
end