local function makeClassCheckFromArray(array)
	return function(ref)
		for _, className in ipairs(array) do
			if ref:IsA(className) then
				return true
			end
		end

		return
			false,
			("Ref type %q is not allowed to have this unit!")
				:format(tostring(ref))
	end
end

local function isAllowedOnRef(staticUnit, ref)
	if staticUnit.refCheck == nil then
		return true
	end

	if type(staticUnit.refCheck) == "table" then
		staticUnit.refCheck = makeClassCheckFromArray(staticUnit.refCheck)
	end

	return staticUnit.refCheck(ref)
end

return {
	isAllowedOnRef = isAllowedOnRef;
}