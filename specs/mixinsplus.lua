require 'luacov'
local class = require('30log-plus')

-- Declared here to cope with the way telescope handles _ENV. We use it in the
-- replicated tests
local instance, c1, c2

context('mixinsplus', function()

	local aclass
	local chain1, chain2, intA, intB, intC, intD -- mixins

	local function concat(v1, v2)
		return (v1 or "")..(v2 or "")
	end

	before(function()

		aclass = class("",{
			ChainA = function(self)
				self.a = concat(self.a, "XX")
				return true
			end,
			ChainB = function(self)
				self.a = concat(self.a, "XX")
				self.b = concat(self.b, "XX")
				return false
			end,
			bar = function(self)
				self.barV = concat(self.barV, "XX")
			end,
			Int1 = function(self)
				self.e = concat(self.e, "XX")
				return true
			end,
			Int3 = function(self)
				self.g = concat(self.g, "XX")
				return true
			end,
			Int4 = function(self)
				self.h = concat(self.g, "XX")
				return false
			end,
			Int5 = function(self)
				self.i = concat(self.g, "XX")
				return true
			end
		})

		chain1   = { name = "chain1",
			ChainA = function(self)
				self.a = concat(self.a, "C1")
				self.b = concat(self.b, "C1")
				return true
			end,
			ChainB = function(self)
				self.a = concat(self.a, "C1")
				self.b = concat(self.b, "C1")
				return false
			end,
			ChainC = function(self)
				self.d = concat(self.d, "C1")
				return true
			end,
			-- adding absent functions dooesn't raise errors
			chained = {"ChainA","ChainB","ChainC","foo","bar"}
		}
		chain2   = { name = "chain2",
			ChainA  = function(self)
				self.a = concat(self.a, "C2")
				self.b = concat(self.b, "C2")
				self.c = concat(self.c, "C2")
				return true
			end,
			ChainB = function(self)
				self.a = concat(self.a, "C2")
				self.b = concat(self.b, "C2")
				self.c = concat(self.c, "C2")
				return true
			end,
			ChainC = function(self)
				self.d = concat(self.d, "C2")
				return true
			end,
			chained = {"ChainA","ChainB","ChainC"}
		}
		intA = { name = "int1a",
			BeforeInt1 = function(self)
				self.e = concat(self.e, "Ba")
				return true
			end,
			AfterInt1 = function(self)
				self.e = concat(self.e, "Aa")
				return true
			end,
			BeforeInt2 = function(self)
				self.f = concat(self.f, "Ba")
				return true
			end,
			AfterInt2 = function(self)
				self.f = concat(self.f, "Aa")
				return true
			end,
			BeforeInt3 = function(self)
				self.g = concat(self.g, "Ba")
				return false
			end,
			AfterInt3 = function(self)
				self.g = concat(self.g, "Aa")
				return true
			end,
			BeforeInt4 = function(self)
				self.h = concat(self.h, "Ba")
				return true
			end,
			AfterInt4 = function(self)
				self.h = concat(self.h, "Aa")
				return true
			end,
			BeforeInt5 = function(self)
				self.i = concat(self.i, "Ba")
				return true
			end,
			AfterInt5 = function(self)
				self.i = concat(self.i, "Aa")
				return false
			end,
			AfterInt6 = function(self)
				self.j = concat(self.j, "Aa")
				return false
			end,
			-- adding absent functions dooesn't raise errors
			intercept = {"Int1", "Int2", "Int3", "Int4", "Int5", "Int6", "foo","bar"}
		}
		intB = { name = "int1b",
			BeforeInt1 = function(self)
				self.e = concat(self.e, "Bb")
				return true
			end,
			AfterInt1 = function(self)
				self.e = concat(self.e, "Ab")
				return true
			end,
			BeforeInt2 = function(self)
				self.f = concat(self.f, "Bb")
				return true
			end,
			AfterInt2 = function(self)
				self.f = concat(self.f, "Ab")
				return true
			end,
			BeforeInt3 = function(self)
				self.g = concat(self.g, "Bb")
				return true
			end,
			AfterInt3 = function(self)
				self.g = concat(self.g, "Ab")
				return true
			end,
			BeforeInt4 = function(self)
				self.h = concat(self.h, "Bb")
				return true
			end,
			AfterInt4 = function(self)
				self.h = concat(self.h, "Ab")
				return true
			end,
			BeforeInt5 = function(self)
				self.i = concat(self.i, "Bb")
				return true
			end,
			AfterInt5 = function(self)
				self.i = concat(self.i, "Ab")
				return true
			end,
			BeforeInt6 = function(self)
				self.j = concat(self.j, "Bb")
				return true
			end,
			intercept = {"Int1", "Int2", "Int3", "Int4", "Int5", "Int6"}
		}
		intC = { name = "intC",
			ChainA = function(self)
				self.a = concat(self.a, "C3")
				return true
			end,
			BeforeChainA = function(self)
				self.a = concat(self.a, "Bc")
				return true
			end,
			AfterChainA = function(self)
				self.a = concat(self.a, "Ac")
				return true
			end,
			chained = {"ChainA"},
			intercept = {"ChainA"}
		}
		intD = { name = "intD",
			BeforeChainA = function(self)
				self.a = concat(self.a, "Bd")
				return true
			end,
			AfterChainA = function(self)
				self.a = concat(self.a, "Ad")
				return true
			end,
			intercept = {"ChainA"}
		}
	end)

	-- Avoid test duplication
	local function ChainTests()
		test("before the correspondent class method", function()
			instance:ChainA()
			assert_equal(instance.a, "C1C2XX")
			assert_equal(instance.b, "C1C2")
			assert_equal(instance.c, "C2")
			assert_nil(instance.d)
		end)
		test("even if not implemented by the base class", function()
			instance:ChainC()
			assert_equal(instance.d, "C1C2")
		end)
		test("but stop if a method in the sequence returns false.", function()
			instance:ChainB()
			assert_equal(instance.a, "C1")
			assert_equal(instance.b, "C1")
			assert_nil  (instance.c)
			assert_nil(instance.d)
		end)
	end
	context('Chained methods', function()
		context('absent from the mixin declaring them', function()
			test("should not raise an error or affect class behavior.", function()
				instance = aclass:ext():with(chain1):_end()()
				instance:bar()
				assert_equal(instance.barV, "XX")
			end)
		end)
		context('run in the order their mixins are declared', function()
			context('with varargs', function()
				before(function()
					instance = aclass:ext():with(chain1, chain2):_end()()
				end)
				ChainTests()
			end)
			context('with piped methods', function()
				before(function()
					instance = aclass:ext():with(chain1):with(chain2):_end()()
				end)
				ChainTests()
			end)
		end)
	end)

	-- Avoid test duplication
	local function intTests()
		test("should run before and after the intercepted one", function()
			instance = c1()
			instance:Int1()
			assert_equal(instance.e, "BaXXAa")
		end)
		test("with later intercepts enclosing earlier ones", function()
			instance = c2()
			instance:Int1()
			assert_equal(instance.e, "BbBaXXAaAb")
		end)
		test("even if not implemented by the base class", function()
			instance = c1()
			instance:Int2()
			assert_equal(instance.f, "BaAa")
			instance = c2()
			instance:Int2()
			assert_equal(instance.f, "BbBaAaAb")
		end)
		test("or missing one of their decorators", function()
			instance = c1()
			instance:Int6()
			assert_equal(instance.j, "Aa")
			instance = c2()
			instance:Int6()
			assert_equal(instance.j, "BbAa")
		end)
		test("but stop if a method in the sequence returns false.", function()
			instance = c2()
			instance:Int3()
			assert_equal(instance.g, "BbBa")
			instance:Int4()
			assert_equal(instance.h, "BbBaXX")
			instance:Int5()
			assert_equal(instance.i, "BbBaXXAa")
		end)
	end
	context('Intercepting methods', function()
		context('absent from the mixin declaring them', function()
			test("should not raise an error or affect class behavior.", function()
				instance = aclass:ext():with(intA):_end()()
				instance:bar()
				assert_equal(instance.barV, "XX")
			end)
		end)
		context('with varargs', function()
			before(function()
				c1 = aclass:ext():with(intA):_end()
				c2 = aclass:ext():with(intA, intB):_end()
			end)
			intTests()
		end)
		context('with piped methods', function()
			before(function()
				c1 = aclass:ext():with(intA):_end()
				c2 = aclass:ext():with(intA):with(intB):_end()
			end)
			intTests()
		end)
	end)

	-- Avoid test duplication
	local function mixTests()
		test("should first process chains, then enclose them in intercepts.", function()
			instance:ChainA()
			assert_equal(instance.a, "BdBcC1C2C3XXAcAd")
		end)
	end
	context('Using both kind of special methods', function()
		context('within the same mixin', function()
			test('should follow the sequencing rules for both.', function()
					instance = aclass:ext():with(intC):_end()()
					instance:ChainA()
					assert_equal(instance.a, "BcC3XXAc")
			end)
		end)
		context('with different mixins', function()
			context('with varargs', function()
				before(function()
					instance =
						aclass:ext():with(chain1, chain2, intC, intD):_end()()
				end)
				mixTests()
			end)
			context('with piped methods', function()
				before(function()
					instance = aclass:ext()
						:with(chain1):with(chain2):with(intC):with(intD):_end()()
				end)
				mixTests()
			end)
		end)
	end)

	context('Working with sub classes', function()
		test('should be commutative if both types get the same order', function()
			local bclass = aclass:ext():with(chain1):_end()
			local cclass = bclass:ext():with(chain2):_end()
			local instD  = cclass:ext():with(intD  ):_end()()
			local dclass = aclass:ext():with(chain1):_end()
			local eclass = dclass:ext():with(intD  ):_end()
			local instF  = eclass:ext():with(chain2):_end()()
			local fclass = aclass:ext():with(intD  ):_end()
			local gclass = fclass:ext():with(chain1):_end()
			local instH  = gclass:ext():with(chain2):_end()()
			instD:ChainA()
			instF:ChainA()
			instH:ChainA()
			assert_equal(instD.a, instF.a)
			assert_equal(instD.a, instH.a)
		end)
		test('and give the same results as with a single class.', function()
			local bclass = aclass:ext():with(chain1):_end()
			local cclass = bclass:ext():with(chain2):_end()
			local dclass = cclass:ext():with(intC):_end()
			local instE  = dclass:ext():with(intD):_end()()
			local instX = aclass:ext()
				:with(chain1):with(chain2):with(intC):with(intD):_end()()
			instE:ChainA()
			instX:ChainA()
			assert_equal(instE.a, instX.a)
		end)
	end)
end)
