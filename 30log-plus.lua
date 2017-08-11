-- @LICENSE MIT
-- @author: Yonaba, CPE

local assert       = assert
local pairs        = pairs
local type         = type
local tostring     = tostring
local setmetatable = setmetatable

local _class
local baseMt     = {}

local reqPath = string.sub(..., 1, string.len(...) - string.len("30log-plus"))
local list = require(reqPath .. "linkedList")

local _instances = list()
local _classes   = list()

local function assert_call_from_class(class, method)
	assert(_classes:contains(class), ('Wrong method call. Expected class:%s.'):format(method))
end

local function assert_call_from_instance(instance, method)
	assert(_instances:contains(instance), ('Wrong method call. Expected instance:%s.'):format(method))
end

local function deep_copy(t, dest, aType, reserved)
	reserved = reserved or {}
	t = t or {}
	local r = dest or {}
	for k,v in pairs(t) do
		if not reserved[k] then
			if aType ~= nil and type(v) == aType then
				r[k] = (type(v) == 'table')
								and ((_classes:contains(v) or _instances:contains(v)) and v or deep_copy(v))
								or v
			elseif aType == nil then
				r[k] = (type(v) == 'table')
						and k~= '__index' and ((_classes:contains(v) or _instances:contains(v)) and v or deep_copy(v))
								or v
			end
		end
	end
	return r
end

local reservedKeys = {
	__index      = true,
	mixins       = true,
	__subclasses = true,
	__instances  = true,
}

local function instantiate(call_init, self, ...)
	assert_call_from_class(self, 'new(...) or class(...)')
	local instance = {class = self}
	_instances:push(instance, tostring(instance))
	deep_copy(self, instance, 'table', reservedKeys)
	instance = setmetatable(instance,self)
	if call_init and self.init then
		if type(self.init) == 'table' then
		deep_copy(self.init, instance)
		else
			self.init(instance, ...)
		end
	end
	return instance
end

local function extend(self, name, extra_params)
	assert_call_from_class(self, 'extend(...)')
	if _classes:contains(extra_params) then
		return extra_params:extend(name)
	end
	local heir = deep_copy(extra_params, deep_copy(self, {}, "function"))
	_classes:push(heir, tostring(heir))
	self.__subclasses[heir] = true
	heir.name    = extra_params and extra_params.name or name
	heir.__index = heir
	heir.super   = self
	heir.mixins  = self.mixins:copy()
	return setmetatable(heir,self)
end

local chainHandlers = require(reqPath .. "chainHandlers")

local function verifyCallback(obj, name, callbacks)
	if type(obj[name]) == "function" then
		callbacks:get(name, obj[name])
	end
end

local function construcIntercepts(obj, mixin, before, after, objCallbacks)
	for _ , name in ipairs(mixin.intercept or {}) do
		local verify = false
		if type(mixin["Before"..name]) == "function" then
			before:get(name, list()):prepend(mixin["Before"..name])
			verify = true
		end
		if type(mixin["After"..name]) == "function" then
			after:get(name, list()):push(mixin["After"..name])
			verify = true
		end
		if verify then verifyCallback(obj, name, objCallbacks) end
	end
end

local function constructHandlers(obj, mixin, handlers, objCallbacks)
	for _ , name in ipairs(mixin.chained or {}) do
		if type(mixin[name]) == "function" then
			handlers:get(name, list()):push(mixin[name])
			verifyCallback(obj, name, objCallbacks)
		end
	end
end

local reserved = {
	init  = true,
	setup = true,
}

local function checkChain(tbl, key)
	for _, name in ipairs(tbl) do
		if key == name then return false end
	end
	return true
end

local function checkInter(tbl, key)
	for _, name in ipairs(tbl) do
		if key == "Before"..name or key == "After"..name then return false end
	end
	return true
end

local function validFunc(mixin, key)
	if type(mixin[key]) ~= "function" then return false end
	if reserved[key] then return false end
	local intercept = mixin.intercept or {}
	local chained   = mixin.chained   or {}
	return (          #intercept        <            #chained        ) and
		   (checkInter(intercept, key) and checkChain(chained  , key)) or
		   (checkChain(chained  , key) and checkInter(intercept, key))
end

local function new(self,...)
	local lineage = list()
	local obj = self
	repeat
		lineage:prepend(obj)
		obj = obj.super
	until obj == nil
	for class in lineage:iterate() do
		if class.setup then class.setup(self, ...) end
	end

	local handlers, selfCallbacks = list(), list()
	local before  , after         = list(), list()

	for mixin in self.mixins:iterate() do
		constructHandlers(self, mixin, handlers, selfCallbacks)
		for key, func in pairs(mixin) do
			if validFunc(mixin, key) then
				self[key] = func
			end
		end
		if mixin.setup then mixin.setup(self, ...) end
		construcIntercepts(self, mixin, before, after, selfCallbacks)
	end

	for name, callback in selfCallbacks:iterate() do
		handlers:get(name, list()):push(callback)
	end

	for name, callbacks in before:iterate() do
		local _handlers = handlers:get(name, list())
		_handlers = callbacks:join(_handlers)
		handlers:set(name, _handlers)
	end
	for name, callbacks in after:iterate() do
		local _handlers = handlers:get(name, list())
		_handlers = _handlers:join(callbacks)
		handlers:set(name, _handlers)
	end
	local nObj = instantiate(true, self, ...)
	chainHandlers(nObj, handlers)
	return nObj
end

local function with(self,...)
	assert_call_from_class(self, 'with(mixin)')
	for _, mixin in ipairs({...}) do
		assert(self.mixins:push(mixin), ('Attempted to include a mixin which was already included in %s'):format(tostring(self)))
	end
	return self
end

local function without(self, ...)
	assert_call_from_class(self, 'without(mixin)')
	for _, mixin in ipairs({...}) do
		assert(self.mixins:contains(mixin), ('Attempted to remove a mixin which is not included in %s'):format(tostring(self)))
		self.mixins:remove(mixin)
	end
	return self
end

local function bind(f, v)
	return function(...) return f(v, ...) end
end

local default_filter = function() return true end

baseMt = {
	__call = function (self,...) return self:new(...) end,

	__tostring = function(self,...)
		if _instances:contains(self) then
			return ("instance of '%s' (%s)"):
			format(
				rawget(self.class,'name') or '?',
				_instances:get(self)
			)
		end

		if _classes:contains(self) then
			return	("class '%s' (%s)"):
			format(
				rawget(self,'name') or '?',
				_classes:get(self)
			)
		end
	end
}

_classes:push(baseMt)
setmetatable(baseMt, {__tostring = baseMt.__tostring})

local class = {
	isClass   = function(t) return _classes:contains(t) end,
	isInstance = function(t) return _instances:contains(t) end,
}

_class = function(name, attr)
	--TODO: deep_copy removal
	local c = deep_copy(attr)
	_classes:push(c, tostring(c))
	c.name = name or c.name
	c.__tostring = baseMt.__tostring
	c.__call = baseMt.__call
	c.create = bind(instantiate, false)
	c.extend = extend
	c.__index = c

	c.mixins = list()
	c.__instances = setmetatable({},{__mode = 'k'})
	c.__subclasses = setmetatable({},{__mode = 'k'})

	c.subclasses = function(self, filter, ...)
		assert_call_from_class(self, 'subclasses(class)')
		filter = filter or default_filter
		local subclasses = {}
		for class in _classes:iterate() do
			if class ~= baseMt and class:subclassOf(self) and filter(class,...) then
				subclasses[#subclasses + 1] = class
			end
		end
		return subclasses
	end

	c.instances = function(self, filter, ...)
		assert_call_from_class(self, 'instances(class)')
		filter = filter or default_filter
		local instances = {}
		for instance in _instances:iterate() do
			if instance:instanceOf(self) and filter(instance, ...) then
				instances[#instances + 1] = instance
			end
		end
		return instances
	end

	c.subclassOf = function(self, superclass)
		assert_call_from_class(self, 'subclassOf(superclass)')
		assert(class.isClass(superclass), 'Wrong argument given to method "subclassOf()". Expected a class.')
		local super = self.super
		while super do
			if super == superclass then return true end
			super = super.super
		end
		return false
	end

	c.classOf = function(self, subclass)
		assert_call_from_class(self, 'classOf(subclass)')
		assert(class.isClass(subclass), 'Wrong argument given to method "classOf()". Expected a class.')
		return subclass:subclassOf(self)
	end

	c.instanceOf = function(self, fromclass)
		assert_call_from_instance(self, 'instanceOf(class)')
		assert(class.isClass(fromclass), 'Wrong argument given to method "instanceOf()". Expected a class.')
		return ((self.class == fromclass) or (self.class:subclassOf(fromclass)))
	end

	c.cast = function(self, toclass)
		assert_call_from_instance(self, 'instanceOf(class)')
		assert(class.isClass(toclass), 'Wrong argument given to method "cast()". Expected a class.')
		setmetatable(self, toclass)
		self.class = toclass
		return self
	end

	c.includes = function(self, mixin)
		assert_call_from_class(self,'includes(mixin)')
		return self.mixins:contains(mixin)
	end

	c.with = with

	c.new = new

	c.without = without

	return setmetatable(c, baseMt)
end

class._DESCRIPTION = '30 lines library for object orientation in Lua, plus some features'
class._VERSION     = '30log-plus v0.0.0'
class._URL         = 'http://github.com/cpeosphoros/30log-plus'
class._LICENSE     = 'MIT LICENSE <http://www.opensource.org/licenses/mit-license.php>'

return setmetatable(class,{__call = function(_,...) return _class(...) end })