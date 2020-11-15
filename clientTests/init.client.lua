local ReplicatedStorage = game:GetService("ReplicatedStorage")
local tests = {}

function tests.invoke_test(...)
	require(ReplicatedStorage.Packages.TestEZ).TestBootstrap:run(...)
	return
end

ReplicatedStorage:WaitForChild("__TestRPC").OnClientInvoke = function(name, ...)
	return tests[name](...)
end