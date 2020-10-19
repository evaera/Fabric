local function getOrCreate(parent, name, class)
	local instance = parent:FindFirstChild(name)

	if not instance then
		instance = Instance.new(class)
		instance.Name = name
		instance.Parent = parent
	end

	return instance
end

return {
	getOrCreate = getOrCreate
}