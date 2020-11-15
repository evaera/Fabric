local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local __TestRPC = Instance.new("RemoteFunction")
__TestRPC.Name = "__TestRPC"
__TestRPC.Parent = ReplicatedStorage

return function(name, ...)
	local plr = Players:GetPlayers()[1]
	while not plr do
		wait()
		plr = Players:GetPlayers()[1]
	end
	return __TestRPC:InvokeClient(plr, name, ...)
end