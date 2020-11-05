local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(ReplicatedStorage.Packages.TestEZ).TestBootstrap:run({
	ReplicatedStorage.Packages.Fabric
})