local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FabricLib = require(ReplicatedStorage.Packages.Fabric)

local fabric = FabricLib.Fabric.new("example")
FabricLib.useReplication(fabric)
FabricLib.useTags(fabric)

fabric:registerUnitsIn(script.units)