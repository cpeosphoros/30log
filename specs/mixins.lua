require 'luacov'
local class = require('30log-plus')

context('mixins', function()

	local aclass, asubclass
	local instance, sub_instance
	local mixin_foo, mixin_bar, mixin_baz, mixin_mix

	before(function()
		mixin_foo     = {foo = function() end}
		mixin_bar     = {bar = function() end}
		mixin_baz     = {baz = function() end}
		mixin_mix     = {f = function() end, g = true}
		aclass        = class("A")
		asubclass     = aclass:extend("SUB")
		instance      = aclass()
		sub_instance  = asubclass()
	end)

	context('with()', function()

		local instance

		before(function()
			instance = asubclass:extend():with(mixin_mix)()
		end)

		test('adds mixins to classes', function()
			assert_type(instance.f, 'function')
		end)

		test('only functions are included', function()
			assert_nil(instance.g)
			assert_true(mixin_mix.g)
		end)

		test('including a mixin twice raises an error', function()
			assert_false(aclass:includes(mixin_mix))
			local bclass = aclass:extend("B"):with(mixin_mix)
			assert_true(bclass:includes(mixin_mix))
			assert_error(function()
				local _ = bclass:extend("C"):with(mixin_mix)
			end)
		end)

		test('can take a vararg of mixins', function()
			local i = aclass:extend()
						:with(mixin_foo, mixin_bar, mixin_baz)()
			assert_type(i.foo, 'function')
			assert_type(i.bar, 'function')
			assert_type(i.baz, 'function')
		end)

		test('or just use chaining', function()
			local i = aclass:extend()
						:with(mixin_foo)
						:with(mixin_bar)
						:with(mixin_baz)()
			assert_type(i.foo, 'function')
			assert_type(i.bar, 'function')
			assert_type(i.baz, 'function')
		end)
	end)

	context('includes', function()

		local bclass, cclass

		before(function()
			bclass = aclass:extend()
				:with(mixin_foo, mixin_bar, mixin_baz, mixin_mix)
			cclass = bclass:extend()
		end)

		test('returns true if a class includes a mixin', function()
			assert_true(bclass:includes(mixin_foo))
			assert_true(bclass:includes(mixin_bar))
			assert_true(bclass:includes(mixin_baz))
			assert_true(bclass:includes(mixin_mix))
		end)

		test('and also when a superclass of the class includes a mixin', function()
			assert_true(cclass:includes(mixin_foo))
			assert_true(cclass:includes(mixin_bar))
			assert_true(cclass:includes(mixin_baz))
			assert_true(cclass:includes(mixin_mix))
		end)

	end)

	context('without()', function()

		local bclass

		before(function()
			bclass = aclass:extend():
				with(mixin_foo, mixin_bar, mixin_baz, mixin_mix)
		end)

		test('removes a given mixin from a class', function()
			local cclass = bclass:extend():without(mixin_mix)
			assert_false(cclass:includes(mixin_mix))
			local dclass = cclass:extend()
			assert_false(cclass:includes(mixin_mix))
			assert_nil(cclass.f)
			assert_nil(dclass.f)
			assert_nil(cclass().f)
		end)

		test('removing a mixin which is not included raises an error', function()
			assert_true(bclass:includes(mixin_mix))
			local cclass = bclass:extend():without(mixin_mix)
			assert_error(function()
				local _ = cclass:extend():without(mixin_mix)
			end)
		end)

		test('can also take a vararg of mixin', function()
			local cclass = bclass:extend():without(mixin_foo, mixin_bar, mixin_baz)
			assert_false(cclass:includes(mixin_foo))
			assert_false(cclass:includes(mixin_bar))
			assert_false(cclass:includes(mixin_baz))
		end)

		test('or just use chaining', function()
			local cclass = bclass:extend()
								:without(mixin_foo)
								:without(mixin_bar)
								:without(mixin_baz)
			assert_false(cclass:includes(mixin_foo))
			assert_false(cclass:includes(mixin_bar))
			assert_false(cclass:includes(mixin_baz))
		end)

	end)

end)
