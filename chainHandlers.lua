-- @LICENSE MIT
-- @author: CPE

return function(base, handlers)
	for handler, callbacks in handlers:iterate() do
		base[handler] = function(...)
			for callback in callbacks:iterate() do
				local res = callback(...)
				if not res then return false end
			end
			return true
		end
	end
end