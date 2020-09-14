local Comparators = require(script.Parent.Comparators)
local Util = require(script.Parent.Parent.Parent.Shared.Util)

local COMPARATOR_NEAR_DEFAULT = 0.001

return function ()
	describe("Comparators", function()
		it("should compare by reference", function()
			expect(Comparators.reference(1, 1)).to.equal(false)
			expect(Comparators.reference(1, 2)).to.equal(true)
			expect(Comparators.reference({}, {})).to.equal(true)

			local a = {}
			expect(Comparators.reference(a, a)).to.equal(false)
		end)

		it("should compare by value", function()
			expect(Comparators.value(1, 1)).to.equal(false)
			expect(Comparators.value(1, 2)).to.equal(true)
			expect(Comparators.value({}, {})).to.equal(false)
			expect(Comparators.value({1}, {1})).to.equal(false)
			expect(Comparators.value({1}, {2})).to.equal(true)

			local a = {}
			expect(Comparators.value(a, a)).to.equal(false)

			expect(Comparators.value({key = 1}, {key = 1})).to.equal(false)
			expect(Comparators.value({key = 1}, {key = 2})).to.equal(true)

			local nested = {key = 1, sub = {subkey = "hello"}}
			local nestedCopy = Util.deepCopy(nested)
			expect(Comparators.value(nested, nestedCopy)).to.equal(false)
		end)

		it("should compare within a range", function()
			expect(Comparators.within(1)(1, 5)).to.equal(true)
			expect(Comparators.within(1)(1, 1.5)).to.equal(false)

			expect(COMPARATOR_NEAR_DEFAULT > 0).to.equal(true)
			expect(Comparators.near(0, COMPARATOR_NEAR_DEFAULT/2)).to.equal(false)
			expect(Comparators.near(0, COMPARATOR_NEAR_DEFAULT*2)).to.equal(true)
		end)
	end)

	describe("Comparator utilities", function()
		it("should compare by property", function()
			local compare = Comparators.structure({
				reference = Comparators.reference;
				value = Comparators.value;
				near = Comparators.near;
			})

			local t = { x = 1 }

			expect(compare({
				reference = t;
				value = t;
				near = 0;
			}, {
				reference = t;
				value = { x = 1 };
				near = 0.0001;
			})).to.equal(false)

			expect(compare({
				reference = t;
				new = 5;
			}, {
				reference = t;
			})).to.equal(true)
		end)
	end)
end
