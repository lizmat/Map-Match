[![Actions Status](https://github.com/lizmat/Map-Match/actions/workflows/linux.yml/badge.svg)](https://github.com/lizmat/Map-Match/actions) [![Actions Status](https://github.com/lizmat/Map-Match/actions/workflows/macos.yml/badge.svg)](https://github.com/lizmat/Map-Match/actions) [![Actions Status](https://github.com/lizmat/Map-Match/actions/workflows/windows.yml/badge.svg)](https://github.com/lizmat/Map-Match/actions)

NAME
====

Map::Match - Provide a Map where keys are regular expressions

SYNOPSIS
========

```raku
use Map::Match;

my %m is Map::Match = foo => 42, b16ar => 666, baz18 => 137;

.say for %m<a>;  # 666␤137␤, same as / a /

.say for %m{ / \d >> / };    # 137␤

.say for %m{ / \d >> / }:k;  # baz18␤

.say for %m( / \d >> /, :k);  # baz18␤
```

DESCRIPTION
===========

Map::Match provides an implementation of the `Map` interface where key values are interpreted as regular expressions. This has the following implications with regards to the normal behaviour of `Map`s:

CAN RETURN MORE THAN ONE
------------------------

Since a regular expression can match multiple times, you can receive more than one value back from a single key. Therefore, a `Slip` will always be returned as the value.

ALWAYS A SLIP
-------------

The value returned from any `Map` access is **always** a `Slip`, albeit potentially empty. This is different from a normal `Map` where `Nil` would be returned when specifying a key that does not exist in the `Map`.

NON-REGEX KEY ASSUMED TO BE REGEX
---------------------------------

If you specify a `Str` as a key, or something that can be coerced to a `Str`, it will be interpreted as being interpolated in a `Regex` with `:ignorecase` and `:ignoremark` enabled.

CAVEATS
-------

This module exports a `postcircumfix { }` candidate that allows access to a `Map::Match` object just like an ordinary `Hash` or `Map`. However, if `Map::Match` is used in a module, and that module returns a `Map::Match` object, then in that scope, that `postcircumfix { }` candidate won't be known, causing `{"foo"}` using the standard semantics, producing weird results.

For that situation, you can use the alternate interface, which is to directly call the `Map::Match` object with the desired arguments:

```raku
# postcircumfix interface
.say for %m{ / \d >> / }:k;  # baz18␤

# alternate interface
.say for %m( / \d >> /, :k);  # baz18␤
```

Of course, it is always an option to always use the alternate interface to prevent confusion, and potential bugs when refactoring code. And the direct interface is actually a bit faster, as it has one less level of indirection.

AUTHOR
======

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/Map-Match . Comments and Pull Requests are welcome.

If you like this module, or what I’m doing more generally, committing to a [small sponsorship](https://github.com/sponsors/lizmat/) would mean a great deal to me!

COPYRIGHT AND LICENSE
=====================

Copyright 2021, 2022, 2023, 2024 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

