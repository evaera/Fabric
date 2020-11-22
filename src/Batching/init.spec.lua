local Promise = require(script.Parent.Parent.Parent.Promise)
local FabricLib = require(script.Parent.Parent)
local Fabric = FabricLib.Fabric

return function()
	if true then return end

	local fabric, event

	local function makeUnitDefinition(callback)
		return {
			name = "test";
			batch = function(on)
				return {
					on.event(event.Event, callback)
				}
			end
		}
	end

	beforeEach(function()
		fabric = Fabric.new("batching")
		FabricLib.useBatching(fabric)
		event = Instance.new("BindableEvent")
	end)

	describe("Batching", function()
		it("should loop over everything", function()
			local refs = {}
			for i = 1, 10 do
				refs[i] = {}
			end

			local hasRan = false
			local staticUnit = makeUnitDefinition(function(list)
				expect(#list).to.equal(#refs)
				hasRan = true
				for _, unit in ipairs(list) do
					unit:mergeBaseLayer({
						testValue = true
					})
				end
			end)
			fabric:registerUnit(staticUnit)

			for _, ref in ipairs(refs) do
				fabric:getOrCreateUnitByRef(staticUnit, ref):mergeBaseLayer({})
			end

			event:Fire() -- ☠️🏴
			expect(hasRan).to.equal(true)

			for _, ref in ipairs(refs) do
				expect(fabric:getUnitByRef(staticUnit, ref):get("testValue")).to.be.ok()
			end
		end)

		it("should remove refs from batch on destruction", function()
			local refs = {}
			for i = 1, 10 do
				refs[i] = {}
			end

			local hasRan = false
			local staticUnit = makeUnitDefinition(function(list)
				expect(#list).to.equal(#refs - 1)
				hasRan = true
				for _, unit in ipairs(list) do
					unit:mergeBaseLayer({
						testValue = true
					})
				end
			end)
			fabric:registerUnit(staticUnit)

			for _, ref in ipairs(refs) do
				fabric:getOrCreateUnitByRef(staticUnit, ref):mergeBaseLayer({})
			end
			fabric:removeAllUnitsWithRef(refs[1])

			event:Fire() -- ☠️🏴
			expect(hasRan).to.equal(true)
		end)

		it("should fire every interval", function()
			local times = {}
			local intervalUnit = {
				name = "test";
				batch = function(on)
					return {
						on.interval(1/6, function(list)
							list[1]:mergeBaseLayer({
								testValue = list[1]:get("testValue") + 1
							})
							table.insert(times, os.clock())
						end)
					}
				end
			}
			fabric:registerUnit(intervalUnit)

			local ref = {}
			local unit = fabric:getOrCreateUnitByRef(intervalUnit, ref)
			unit:mergeBaseLayer({
				testValue = 0
			})
			Promise.delay(5.2/6):await()

			expect(math.abs(unit:get("testValue") - 5) <= 1).to.equal(true)
			fabric:removeAllUnitsWithRef(ref)
		end)
	end)

end