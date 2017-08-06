-- @LICENSE MIT
-- @author: CPE

return function(base, handlers)
	for handler, callbacks in pairs(handlers) do
		base[handler] = function(...)
			for _, callback in ipairs(callbacks) do
				local res = callback(...)
				if not res then return false end
			end
			return true
		end
	end
end