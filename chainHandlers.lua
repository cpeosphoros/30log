-- @LICENSE MIT
-- @author: CPE

local function chainHandlers(base, handlers)
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

return chainHandlers