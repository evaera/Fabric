local RunService = game:GetService("RunService")

local ServerReplicator = require(script.ServerTransmitter)
local ClientReplicator = require(script.ClientTransmitter)
local registerReplicator = require(script.Replicator)

return function (fabric)
	fabric.transmitter = (RunService:IsServer() and ServerReplicator or ClientReplicator).new(fabric)

	registerReplicator(fabric)
end
