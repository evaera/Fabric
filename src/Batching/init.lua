local RunService = game:GetService("RunService")

--[[
	Looks for a batch key inside of components

	If is true or function, we maintain an array of all of the components
	We add a function to fabric which lets you retrieve this array
	If function, we call it on component registration to determine the events you want to do
]]
local Promise = require(script.Parent.Parent.Promise)
local SinglePromiseEvent = require(script.SinglePromiseEvent)

local dt = 1 / 60

RunService.Heartbeat:Connect(function(step)
	dt = step
end)

local batchConstructors = {
	event = function(event, callback)
		return {
			event = event,
			callback = callback
		}
	end,

	interval = function(duration, callback)
		local intervalEvent = SinglePromiseEvent.new(function(fire)
			return function(_, _, isCancelled)
				local loop

				loop = function()
					return Promise.try(fire):andThenCall(Promise.delay, duration):andThen(function()
						if not isCancelled() then
							return loop()
						end
					end)
				end

				loop()
			end
		end)

		return {
			event = intervalEvent,
			callback = callback
		}
	end,

	spreadInterval = function(duration, callbackCreator)
		local isReady = true
		local needsRestart = false
		local loop

		local intervalEvent = SinglePromiseEvent.new(function(fire)
			return function(_, _, isCancelled)
				loop = function()
					isReady = false

					return Promise.try(fire):andThenCall(Promise.delay, duration):andThen(function()
						if not isCancelled() then
							if isReady then
								return loop()
							else
								needsRestart = true
							end
						end
					end)
				end

				loop()
			end
		end)

		local function becomeReady()
			isReady = true

			if needsRestart then
				needsRestart = false

				loop()
			end
		end

		return {
			event = intervalEvent,
			callback = function(list)
				local callback = callbackCreator()

				local listCopy = {}
				for idx, unit in ipairs(list) do
					listCopy[idx] = unit
				end

				local copyIdx = 1
				local currentIdx = 1
				local seen = 0

				local function stepIdx()
					-- updates indices to match expeted positions
					if copyIdx <= #listCopy and listCopy[copyIdx] ~= list[currentIdx] then
						currentIdx = table.find(list, listCopy[copyIdx]) or currentIdx
					end

					local val = list[currentIdx]
					currentIdx = math.min(#list + 1, currentIdx + 1)
					copyIdx = math.min(#listCopy + 1, copyIdx + 1)
					if val then
						seen += 1
					end
					return val -- return next value to use
				end

				local currentTime = 0
				while currentTime <= duration do
					local remainingUnits = #list - seen
					local remainingTime = duration - currentTime
					local timePerUpdate = remainingTime / remainingUnits -- time we spend per future update (assuming even distribution)
					local updatesToDoNow = math.ceil(dt/timePerUpdate) -- if timePerUpdate < 1, we need to do more than 1 unit of work/frame - so we batch

					local p = Promise.delay(timePerUpdate):andThen(function(timeTaken)
						currentTime += timeTaken
					end)
					for _ = 1, updatesToDoNow do
						local nextUnit = stepIdx()
						if nextUnit then
							local ok, errorValue = coroutine.resume(coroutine.create(callback), nextUnit)

							if not ok then
								warn(errorValue)
							end
						end
					end
					p:await()
				end
				-- failsafe - if we have remaining units to update, we do them now
				if seen < #list then
					for i = seen, #list do
						local ok, errorValue = coroutine.resume(coroutine.create(callback), list[i])

						if not ok then
							warn(errorValue)
						end
					end
				end
				becomeReady()
			end,
		}
	end
}

return function (fabric)
	local batches = {}
	local unitToListeners = {}

	local function setupBatching(staticUnit)
		local unitName = staticUnit.name

		if unitToListeners[unitName] then
			for _, listener in ipairs(unitToListeners[unitName]) do
				listener:Disconnect()
			end

			unitToListeners[unitName] = nil
		end

		if staticUnit.batch then
			-- add listener effect
			staticUnit.effects = staticUnit.effects or {}
			staticUnit.effects._batchListener = function(self)
				batches[unitName] = batches[unitName] or {}
				if self._batchArray == batches[unitName] then
					return
				end

				if unitToListeners[unitName] == nil and typeof(staticUnit.batch) == "function" then
					unitToListeners[unitName] = {}

					for _, listenerDefinition in ipairs(staticUnit.batch(batchConstructors)) do
						table.insert(unitToListeners[unitName], listenerDefinition.event:Connect(function()
							listenerDefinition.callback(batches[unitName])
						end))
					end
				end

				self._batchArray = batches[unitName]

				table.insert(self._batchArray, self)

				self:on("destroy", function()
					table.remove(self._batchArray, table.find(self._batchArray, self))

					if #self._batchArray == 0 then
						for _, listener in ipairs(unitToListeners[unitName]) do
							listener:Disconnect()
						end

						batches[unitName] = nil
						unitToListeners[unitName] = nil
					end
				end)
			end
		end
	end

	fabric:on("unitRegistered", setupBatching)
	fabric:on("unitHotReloaded", setupBatching)
end
