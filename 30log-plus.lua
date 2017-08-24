-- @LICENSE MIT
-- @author: Yonaba, CPE

local reqPath = string.sub(..., 1, string.len(...) - string.len("30log-plus"))
local meta    = require(reqPath .. "meta")

local class = {
	_DESCRIPTION = '30 lines library for object orientation in Lua, plus some features',
	_VERSION     = '30log-plus v0.0.0'                                                 ,
	_URL         = 'http://github.com/cpeosphoros/30log-plus'                          ,
	_LICENSE     = 'MIT LICENSE <http://www.opensource.org/licenses/mit-license.php>'  ,
	isClass      = meta.isClass                                                        ,
	isInstance   = meta.isInstance                                                     ,
	Object       = meta                                                                ,
}

local build = {}
build.__index = build

setmetatable(build,
	{ __call =
		function(_, name)
			return setmetatable({
					mixins  = {}  ,
					mixlook = {}  ,
					name    = name,
				}
				, build
			)
		end
	}
)

function build:with(...)
	for _, mixin in ipairs({...}) do
		assert(type(mixin) == "table", ('Mixins should be table, instead of  %s'):format(type(mixin)))
		assert(not self.mixlook[mixin], ('Attempted to include a mixin %s which was already included in %s'):format(mixin.name and mixin.name or tostring(self.super), tostring(self.super)))
		self.mixins[#self.mixins+1] = mixin
		self.mixlook[mixin] = #self.mixins
	end
	return self
end

function build:without(...)
	local remove = {}
	for _, mixin in ipairs({...}) do
		assert(self.mixlook[mixin], ('Attempted to remove a mixin %s which is not included in %s'):format(mixin.name and mixin.name or tostring(self.super), tostring(self.super)))
		remove[mixin] = true
	end
	local new = {}
	self.mixlook = {}
	for _, mixin in ipairs(self.mixins) do
		if remove[mixin] then
		else
			new[#new+1] = mixin
			self.mixlook[mixin] = #new
		end
	end
	self.mixins = new
	return self
end

function build:_end()
	return meta.pushClass(self)
end

local function ext(self, name, params)
	local heir = build(name)
	for k, v in pairs(params or {}) do
		heir[k] = v
	end
	heir.name  = name and name or (params or {}).name
	heir.super = self
	for i, mixin in ipairs(self.mixins or {}) do
		heir.mixins[i]      = mixin
		heir.mixlook[mixin] = true
	end
	return heir
end

local function extend(self, name, params)
	meta.assertClassCall(self, 'extend(...)')
	return self:ext(name, params):_end()
end

local function includes (self, mixin)
	meta.assertClassCall(self,'includes(mixin)')
	return not not self.mixlook[mixin]
end

local function _class(name, params)
	assert(not meta.isClass(params), "A class cannot be used as attributes.")
	local c  = ext(meta, name, params)
	c.ext      = ext
	c.extend   = extend
	c.new      = meta.new
	c.includes = includes
	return c:_end()
end

return setmetatable(class,{__call = function(_,...) return _class(...) end })