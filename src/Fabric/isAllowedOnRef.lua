local function makeArrayPipelineCheck(array)
	return function(ref)
		for _, className in ipairs(array) do
			if ref:IsA(className) then
				return true
			end
		end

		return
			false,
			("Ref type %q is not allowed to have this component!")
				:format(tostring(ref))
	end
end

local function isAllowedOnRef(staticComponent, ref)
	if staticComponent.refCheck == nil then
		return true
	end

	if type(staticComponent.refCheck) == "table" then
		staticComponent.refCheck = makeArrayPipelineCheck(staticComponent.refCheck)
	end

	return staticComponent.refCheck(ref)
end

return {
	isAllowedOnRef = isAllowedOnRef;
}