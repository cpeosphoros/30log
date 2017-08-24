-- @LICENSE MIT
-- @author: Yonaba, CPE

local reqPath       = string.sub(..., 1, string.len(...) - string.len("meta"))
local deepCopy      = require(reqPath .. "deepcopy")
local chainHandlers = require(reqPath .. "chainHandlers")
local list          = require(reqPath .. "linkedList")

local meta = {name = "Object", __immutable = true}

local instances = {}
local classes   = {}
local iIds      = {}
local nextId    = 0

--------------------------------------------------------------------------------
--                             UTILITIES I
--------------------------------------------------------------------------------

local function assertClassCall(class, method)
	assert(classes[class], ('Wrong method call. Expected class:%s.'):format(method))
end

meta.assertClassCall = assertClassCall

local function assertInstanceCall(instance, method)
	assert(instances[instance], ('Wrong method call. Expected instance:%s.'):format(method))
end

--------------------------------------------------------------------------------
--                               METAMETHODS
--------------------------------------------------------------------------------

function meta:__call(...)
	return self:new(...)
end

function meta:__tostring()
	if instances[self] then
		return ("instance of %s-%s (%s)"):
		format(
			rawget(self.class,'name') or '?',
			self.__id                       ,
			instances[self]
		)
	end

	if classes[self] then
		return	("class %s-%d (%s)"):
		format(
			rawget(self,'name') or '?',
			self.__id                 ,
			classes[self].string
		)
	end

	error()
end

function meta:__index(key)
	if type(key) == "string" then
		local class = meta.isClass(self) and self or self.class
		local result = nil
		if classes[class].methods then
			for k, v in pairs(classes[class].methods) do
				if key == k then
					result = v
					break
				end
			end
		else
			local current = class
			while current do
				result = rawget(current, key)
				if result then break end
				current = rawget(current, "super")
			end
		end
		if result then
			result = deepCopy(result)
			rawset(self, key, result)
		end
		return result
	else
		return meta.__getitem(self, key)
	end
end

function meta:__newindex(key, value)
	assert(not rawget(self, "methods"), "Immutable class fields cannot be set.")
	if type(key) == "string" then
		rawset(self, key, value)
	else
		meta.__setitem(self, key, value)
	end
end

--------------------------------------------------------------------------------
--                               SUBCLASSING
--------------------------------------------------------------------------------

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
	ext      = true,
	extend   = true,
	includes = true,
	init     = true,
	new      = true,
	setup    = true,
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

local function processMixins(methods, mixins)
	local handlers, classCallbacks = list(), list()
	local before  , after          = list(), list()

	for _, mixin in ipairs(mixins or {}) do
		constructHandlers(methods, mixin, handlers, classCallbacks)
		for key, func in pairs(mixin) do
			if validFunc(mixin, key) then
				methods[key] = func
			end
		end
		construcIntercepts(methods, mixin, before, after, classCallbacks)
	end

	return handlers, classCallbacks, before, after
end

local resKeys = {
	__id     = true,
	mixins   = true,
	mixlook  = true,
	name     = true,
	super    = true,
}

local function setup(class)
	iIds[class] = 0

	if class.super ~= meta and not classes[class.super].methods then
		setup(class.super)
	end

	local lineage = {}
	local obj = class
	repeat
		lineage[#lineage + 1] = obj
		obj = obj.super
	until not obj

	local methods = {}

	for i = #lineage, 1, -1 do
		local cSetup = rawget(lineage[i],"setup")
		if cSetup then cSetup(class) end
		for k, v in next, lineage[i], nil do
			if not resKeys[k] then methods[k] = v end
		end
	end

	local mixins = class.mixins
	for _, mixin in ipairs(mixins or {}) do
		if mixin.setup then mixin.setup(class) end
	end

	local handlers, classCallbacks, before, after = processMixins(methods, mixins)
	for name, callback in classCallbacks:iterate() do
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
	chainHandlers(methods, handlers)
	classes[class].methods = methods
end

function meta.pushClass(class)
	assert(not classes[class], "Duplicate class " .. tostring(class))
	assert(type(class) == "table", "Class must be a table instead of " .. type(class))
	classes[class] = {}
	classes[class].string = tostring(class)
	class.__id = nextId
	nextId = nextId + 1

	setmetatable(class, meta)
	return class
end

--------------------------------------------------------------------------------
--                            INSTANCE CREATION
--------------------------------------------------------------------------------


local function pushInstance(instance)
	assert(not instances[instance], "Duplicate instance " .. tostring(instance))
	instances[instance] = tostring(instance)
	local class = instance.class
	iIds[class] = iIds[class] + 1
	instance.__id = class.__id .. "." .. iIds[class]
	setmetatable(instance, meta)
	return instance
end

function meta.new(self, ...)
	assertClassCall(self, 'new(...) or class(...)')
	if not classes[self].methods then
		setup(self)
	end

	local instance = pushInstance({class = self})
	if self.init then self.init(instance, ...) end
	return instance
end

--------------------------------------------------------------------------------
--                             UTILITIES II
--------------------------------------------------------------------------------

function meta.isClass(class)
	return not not classes[class]
end

function meta.isInstance(instance)
	return not not instances[instance]
end

local function defaultFilter()
	return true
end

function meta:subclasses(filter, ...)
	assertClassCall(self, 'subclasses(class)')
	filter = filter or defaultFilter
	local subclasses = {}
	for class in pairs(classes) do
		if class ~= meta and class:subclassOf(self) and filter(class,...) then
			subclasses[#subclasses + 1] = class
		end
	end
	return subclasses
end

function meta:instances(filter, ...)
	assertClassCall(self, 'instances(class)')
	filter = filter or defaultFilter
	local _instances = {}
	for instance in pairs(instances) do
		if instance:instanceOf(self) and filter(instance, ...) then
			_instances[#_instances + 1] = instance
		end
	end
	return _instances
end

function meta:isEqual(other)
	assertClassCall(self, 'isEqual(class)')
	assert(other and meta.isClass(other), 'Wrong argument given to method "isEqual()". Expected a class instead of '..tostring(other))
	if self == other then return true end
	if self.__id   ~= other.__id then return false end
	if self.name ~= other.name then return false end
	if self.super and (other.super and not self.super:isEqual(other.super)) then return false end
	for k, v in pairs(self) do
		if type(v) ~= type(other[k]) then return false end
	end
	return true
end

function meta:subclassOf(class)
	assertClassCall(self, 'subclassOf(superclass)')
	assert(meta.isClass(class), 'Wrong argument given to method "subclassOf()". Expected a class.')
	local super = self.super
	while super do
		if super:isEqual(class) then return true end
		super = super.super
	end
	return false
end

function meta:classOf (class)
	assertClassCall(self, 'classOf(subclass)')
	assert(meta.isClass(class), 'Wrong argument given to method "classOf()". Expected a class.')
	return class:subclassOf(self)
end

function meta:instanceOf(class)
	assertInstanceCall(self, 'instanceOf(class)')
	assert(meta.isClass(class), 'Wrong argument given to method "instanceOf()". Expected a class.')
	return self.class:isEqual(class) or self.class:subclassOf(class)
end

meta.pushClass(meta)
return setmetatable(meta, {__tostring = meta.__tostring})
