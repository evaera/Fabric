local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FabricLib = require(ReplicatedStorage.Packages.Fabric)

local fabric = FabricLib.Fabric.new("example")
FabricLib.useReplication(fabric)
FabricLib.useTags(fabric)
FabricLib.useBatching(fabric)

fabric.DEBUG = false

fabric:registerUnitsIn(ReplicatedStorage.Packages.exampleClientUnits)