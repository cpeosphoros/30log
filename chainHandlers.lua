-- @LICENSE MIT
-- @author: CPE

local function chainHandlers(base, handlers)

	local iterate = handlers.iterate and handlers.iterate or pairs

	for handler, callbacks in iterate(handlers) do
		base[handler] = function(...)
			for _, callback in iterate(callbacks) do
				local res = callback(...)
				if not res then return false end
			end
			return true
		end
	end
end

return chainHandlers