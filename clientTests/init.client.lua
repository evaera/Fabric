local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FabricLib = require(ReplicatedStorage:WaitForChild("Fabric"))

local tests = {}

local fabric = FabricLib.Fabric.new("test")

function tests.test_name()
	return "some_value"
end


ReplicatedStorage:WaitForChild("__TestRPC").OnClientInvoke = function(name, ...)
	return tests[name](...)
end