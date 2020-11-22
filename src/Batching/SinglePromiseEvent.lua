local Promise = require(script.Parent.Parent.Parent.Promise)

local SinglePromiseEvent = {}
SinglePromiseEvent.__index = SinglePromiseEvent

function SinglePromiseEvent.new(executor)
	local self = setmetatable({
		_listener = nil,
	}, SinglePromiseEvent)

	local function fire()
		if self._listener then
			coroutine.wrap(self._listener)()
		end
	end

	self._promise = Promise.defer(function(resolve)
		resolve(Promise.new(executor(fire)):andThen(function()
			self._listener = nil
		end))
	end)

	return self
end

function SinglePromiseEvent:Connect(callback)
	assert(self._listener == nil, "SinglePromiseEvent is already used up")
	assert(self._promise:getStatus() == "Started", "SinglePromiseEvent is already used up")

	self._listener = callback
	return {
		Disconnect = function()
			self._promise:cancel()
			self._listener = nil
		end
	}
end

return SinglePromiseEvent