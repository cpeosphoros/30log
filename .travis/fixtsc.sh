#! /bin/bash

# Fixtelescope to run with lua 5.2 and 5.3
sed 's/compat_env.setfenv/compat_env.setfenv\nlocal unpack = unpack or table.unpack/' ${TRAVIS_BUILD_DIR}/install/luarocks/share/lua/$LUAVER/telescope.lua

# Fix failed assertions not reporting the correct erroneous values
sed 's/a[i] = tostring(v)/a[i] = tostring(args[i])/' ${TRAVIS_BUILD_DIR}/install/luarocks/share/lua/$LUAVER/telescope.lua



