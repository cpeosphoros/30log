-- @LICENSE MIT
-- @author: CPE
-- Loosely based on http://nova-fusion.com/2012/11/16/linked-lists-in-lua/

-- TODO: Have a look at https://john.cs.olemiss.edu/~hcc//csci555/notes/CellLists/Lua/cellList.lua

local list = {}
list.__index = list

local function iterate(self, current)
	if not current then
		local _first = self.first
		if _first then
			return _first.key, _first.value
		else
			return nil, nil
		end
	end
	local node = self.nodes[current]
	if node then
		local _next = node.next
		if _next then
			return  _next.key, _next.value
		end
	end
	return nil, nil
end

--list.__pairs = function(self)
--	return iterate, self, nil
--end,

setmetatable(list,
	{
		__call = function(_, ...)
			local newList = setmetatable({length = 0 }, list)
			newList.nodes = {}
			for _, value in ipairs{...} do newList:push(value) end
			return newList
		end,
	}
)

function list:prepend(key, value)
	--print("list.prepend", key, value)
	value = value or key
	if self.nodes[key] then return false end
	local node = {}
	node.key = key
	node.value = value
	if not self.first then
		-- this is the first node
		self.first = node
		self.last = node
	else
		self.first.prev = node
		node.next = self.first
		self.first = node
	end
	self.nodes[key] = node
	self.length = self.length + 1
	return true
end

local function insertFirst(self, node)
	self.first.prev = node
	node.next = self.first
	self.first = node
end

local function insertLast(self, node)
	self.last.next = node
	node.prev = self.last
	self.last = node
end

function list:push(key, value)
	--print("list.push", key, value)
	value = value or key
	if self.nodes[key] then return false end
	local node = {}
	node.key   = key
	node.value = value
	if not self.first then
		-- this is the first node
		self.first = node
		self.last = node
	else
		if self.ordered then
			if     key < self.first.key then
				insertFirst(self, node)
			elseif key > self.last.key then
				insertLast(self, node)
			else
				local cNode = self.first.next
				while cNode.key < key do
					cNode = cNode.next
				end
				cNode.prev.next = node
				cNode.prev      = node
				node.next       = cNode
			end
		else
			insertLast(self, node)
		end
	end
	self.nodes[key] = node
	self.length = self.length + 1
	return true
end

function list:get(key, default)
	key = key or (self.first and self.first.key)
	if not key then return end
	local node = self.nodes[key]
	if not node then
		if default == nil then return end
		assert(self:push(key, default))
		node = self.nodes[key]
	end
	return node.value
end

function list:set(key, value)
	local node = self.nodes[key]
	if not node then return self:push(key, value) end
	node.value = value
	return true
end

function list:contains(key)
	return not not self.nodes[key]
end

local function recNil(tbl, key)
	repeat
		if tbl[key] == nil then return end
		tbl[key] = nil
		tbl = getmetatable(tbl)
		if tbl then tbl = tbl.__index end
	until tbl == nil
end

function list:remove(key)
	local node = self.nodes[key]
	if not node then return end
	local value = node.value
	if node.next then
		if node.prev then
			node.next.prev = node.prev
			node.prev.next = node.next
		else
			-- this is the first node
			node.next.prev = nil
			self.first = node.next
		end
	elseif node.prev then
		-- this is the last node
		node.prev.next = nil
		self.last = node.prev
	else
		-- this is the only node
		self.first = nil
		self.last =  nil
	end
	recNil(self.nodes, key)
	self.length = self.length - 1
	return key, value
end

function list:pop()
	if not self.last then return end
	return self:remove(self.last.key)
end

function list:iterate()
	return iterate, self, nil
end

function list:copy()
	local newList = list()
	for key, value in self:iterate() do newList:push(key, value) end
	return newList
end

local function recIndex(aTbl, oTbl)
	local mt = getmetatable(aTbl)
	if not mt then
		return setmetatable(aTbl, {__index = oTbl})
	end
	mt.__index = mt.__index and recIndex(mt.__index, oTbl) or oTbl
	return setmetatable(aTbl, mt)
end

function list:join(oList)
	if not (oList.first and oList.last) then return self end
	self.nodes = recIndex(self.nodes, oList.nodes)
	if not self.first then
		self.first = oList.first
		self.last  = oList.last
	else
		self.last.next   = oList.first
		oList.first.prev = self.last
		self.last        = oList.last
	end
	self.length = self.length + oList.length
	oList.first = nil
	oList.last = nil
	oList.nodes = {}
	oList.length = 0
	return self
end

return list