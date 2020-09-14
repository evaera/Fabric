local RunService = game:GetService("RunService")

local ServerReplicator = require(script.ServerReplicator)
local ClientReplicator = require(script.ClientReplicator)

return function (fabric)
	fabric.replicator = (RunService:IsServer() and ServerReplicator or ClientReplicator).new(fabric)
end
