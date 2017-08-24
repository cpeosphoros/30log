local function deepCopy(value, cache, promises, copies)
	cache    = cache    or {}
	promises = promises or {}
	copies   = copies   or {}

	local copy
    if type(value) == 'table' then
--		print(level ..": ".. tostring(value))
		if(cache[value]) then
--			print("Returning cached", cCache[self], "for", self)
			copy = cache[value]
		else
			promises[value] = promises[value] or {}
			copy = {}
			for k, v in next, value, nil do
				local nKey   = promises[k] or deepCopy(k, cache, promises, copies)
				local nValue = promises[v] or deepCopy(v, cache, promises, copies)
				copies[nKey]   = type(k) == "table" and k or nil
				copies[nValue] = type(v) == "table" and v or nil
				copy[nKey] = nValue
			end
			local mt = getmetatable(value)
			if mt then
				setmetatable(copy, mt.__immutable and mt or deepCopy(mt, cache, promises, copies))
			end
--			print("Caching", copy, "for", self)
			cache[value]    = copy
		end
    else -- number, string, boolean, etc
        copy = value
    end

--	if type(value) == "table" then
--		print()
--		print("orig", value)
--		print("copy=",copy)
--		for k, v in pairs(copy) do
--			print("copy", k, v)
--		end
--		for k, v in pairs(cache) do
--			print("cache", k, v)
--		end
--		for k, v in pairs(copies) do
--			print("copies", k, v)
--		end
--	end

	for k, v in pairs(copies) do
		if k == cache[v] then
			copies[k] = nil
		end
	end

	local function correctRec(tbl)
		if type(tbl) ~= "table" then return tbl end

		if copies[tbl] and cache[copies[tbl]] then
			return cache[copies[tbl]]
		end

		local new = {}
		for k, v in pairs(tbl) do
			local oldK = k
			k, v = correctRec(k), correctRec(v)
			if k ~= oldK then
				tbl[oldK] = nil
				new[k] = v
			else
				tbl[k] = v
			end
		end
		for k, v in pairs(new) do
			tbl[k] = v
		end
--		print()
		return tbl
	end
	correctRec(copy)

--	if type(value) == "table" then
--		print("copy=",copy)
--		for k, v in pairs(copy) do
--			print("copy", k, v)
--		end
--		for k, v in pairs(cache) do
--			print("cache", k, v)
--		end
--		for k, v in pairs(copies) do
--			print("copies", k, v)
--		end
--		print("----------------------------------------------------------")
--	end

    return copy
end

return deepCopy