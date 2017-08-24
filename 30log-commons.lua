-- 30log-commons.lua, Interface for Class-Commons, (c) 2012 TsT2005
-- Class-Commons <https://github.com/bartbes/Class-Commons>

local _class = require('30log-plus')

return {
	class = function(name, prototype, parent)
	    parent    = parent    or _class()
		assert(not _class.isClass(prototype), "A class cannot be used as prototype.")
		local klass = parent:extend(name, prototype)
		return klass
	end,

	instance = function(class, ...)
		return class:new(...)
	end
}