local Reducers = require(script.Parent.Reducers)

return function()
	describe("structure", function()
		it("should reduce normally", function()
			local value = Reducers.structure({
				add = Reducers.add,
				multiply = Reducers.multiply,
			})({
				{ add = 3, multiply = 3, default = 1 },
				{ add = 2, multiply = 2, default = 2 },
			})

			expect(value.add).to.equal(5)
			expect(value.multiply).to.equal(6)
			expect(value.default).to.equal(2)
		end)

		it("should pass through with one value with no params", function()
			local layer = { add = 3, multiply = 3, default = 1 }

			local value = Reducers.structure()({
				layer,
			})

			expect(value.add).to.equal(3)
			expect(value.multiply).to.equal(3)
			expect(value.default).to.equal(1)

			expect(value).to.equal(layer)
		end)

		it("should assign with two value", function()
			local layer1 = { add = 3, multiply = 3, default = 1 }
			local layer2 = { add = 2, default = 2 }

			local value = Reducers.structure()({
				layer1,
				layer2
			})

			expect(value.add).to.equal(2)
			expect(value.multiply).to.equal(3)
			expect(value.default).to.equal(2)

			expect(value).to.never.equal(layer1)
			expect(value).to.never.equal(layer2)
		end)
	end)
end