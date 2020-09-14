local Util = {}

function Util.clipMask(data, mask)
	assert(type(data) == "table", "Attempt to mask on a non-table!")

	local clippedData = {}

	for k, v in pairs(data) do
		if mask[k] == true then
			clippedData[k] = v
		elseif type(mask[k]) == "table" then
			clippedData[k] = Util.clipMask(data[k], mask[k])
		end
	end

	return clippedData
end

function Util.find(array, value)
	for i, v in ipairs(array) do
		if v == value then
			return i
		end
	end
end

return Util
