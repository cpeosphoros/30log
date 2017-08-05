![30log logo](https://github.com/Yonaba/30log/raw/master/30log-logo.png)

[![Build Status](https://travis-ci.org/cpeosphoros/30log.png)](https://travis-ci.org/cpeosphoros/30log)
[![Lua](https://img.shields.io/badge/Lua-5.1%2C%205.2%2C%205.3%2C%20JIT-blue.svg)]()
[![License](http://img.shields.io/badge/Licence-MIT-brightgreen.svg)](LICENSE)
[![Coverage Status](https://coveralls.io/repos/Yonaba/30log/badge.png?branch=master)](https://coveralls.io/r/Yonaba/30log?branch=master)

*30log*, in extenso *30 Lines Of Goodness* is a minified framework for [object-orientation](http://lua-users.org/wiki/ObjectOrientedProgramming) in Lua.
It provides  *named* and *unnamed classes*, *single inheritance*, *metamethods* and a basic support for _mixins_. In *30 lines*.<br/>
Well, [somehow](http://github.com/Yonaba/30log#30log-cleanlua).

*30log-plus* is both a fork from and an extension to 30log, with a focus on
stronger support for class initialization and mixins support. We have decided to
keep our changes only to 30log-clean. Those changes will also *not* be pull
requested into Yonaba's repository, as they slightly deviate from his minimalist
approach.

## Wiki

A full documentation is available on the [wiki](https://github.com/cpeosphoros/30log-plus/wiki).
Find the project page at [yonaba.github.io/30log](gttp://yonaba.github.io/30log).

See the module [30log-commons.lua](https://github.com/Yonaba/30log/blob/master/30log-commons.lua).


##Specs

You can run the included specs with [Telescope](https://github.com/norman/telescope) using the following command from Lua from the root foolder:

```
lua tsc -f specs/*
```

##License

This work is [MIT-Licensed](https://raw.githubusercontent.com/cpeosphoros/30log/master/LICENSE).
