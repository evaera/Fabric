local Symbol = {
	_symbols = {}
}

function Symbol.named(name)
	Symbol._symbols[name] = Symbol._symbols[name] or {}

	return Symbol._symbols[name]
end

return Symbol