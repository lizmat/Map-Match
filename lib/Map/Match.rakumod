use Map::Agnostic:ver<0.0.6>:auth<zef:lizmat>;

class Map::Match:ver<0.0.3>:auth<zef:lizmat> does Map::Agnostic {
    has     %!map handles <keys values kv pairs anti-pairs iterator>;
    has Str $!keys;

    my $cursor-init := Match.^lookup("!cursor_init");

    method !keys() {
        $!keys || ($!keys := "\0" ~ %!map.keys.join("\0") ~ "\0")
    }

    my sub key(        %map, str $key) { $key                              }
    my sub value(      %map, str $key) { %map.AT-KEY($key)                 }
    my sub pair(       %map, str $key) { Pair.new: $key, %map.AT-KEY($key) }
    my sub exists(     %map, str $key) { True                              }
    my sub pair-exists(%map, str $key) { Pair.new: $key, True              }

    my sub nogo(@nogo) {
        -> %, $ { Failure.new(X::Adverb.new: :what<slice>, :@nogo) }
    }

    method mapper($exists, $p, $k) is implementation-detail {
        $exists
          ?? $p
            ?? $k
              ?? nogo(<exists p k>)
              !! &pair-exists
            !! &exists
          !! $p
            ?? $k
              ?? nogo(<p k>)
              !! &pair
            !! $k
              ?? &key
              !! &value
    }

    proto method lookup(|) {*}
    multi method lookup(Regex:D $regex, &mapper) is implementation-detail {
        my $found := IterationBuffer.CREATE;
        my $keys := self!keys;

        my $cursor;
        my $key;

        my int $pos;
        my int $left;
        my int $right;
        my int $c;
        while ($pos = (
          $cursor := $regex($cursor-init(Match, $keys, :$c))
        ).pos) > -1 {
            $left  = $keys.rindex("\0", $cursor.from);
            $right = $keys.index( "\0", $pos);

            $key := $keys.substr($left + 1, $right - $left - 1);
            $found.push: mapper(%!map, $key)
              unless $key.contains("\0");  # regex bled into another key
            $c = $right + 1;
        }
        $found
    }
    multi method lookup(Str:D $key, &mapper) is implementation-detail {
        my $found := IterationBuffer.CREATE;
        my $keys := self!keys;
        my int $left;
        my int $right;

        my int $index;
        while $keys.index($key, $index, :i, :m) -> int $this { # cannot be 0
            $left  = $keys.rindex("\0",$this) + 1;
            $right = $keys.index("\0", $this);
            $found.push: mapper(%!map, $keys.substr($left, $right - $left));
            $index = $right + 1;
        }
        $found
    }

    method INIT-KEY($key,$value) { %!map.BIND-KEY($key, $value) }

    proto method AT-KEY(|) {*}
    multi method AT-KEY(Regex:D $key) { self.lookup($key, &value).Slip }
    multi method AT-KEY(Str()   $key) { self.lookup($key, &value).Slip }

    proto method EXISTS-KEY(|) {*}
    multi method EXISTS-KEY(Regex:D $key) { self!keys.contains($key) }
    multi method EXISTS-KEY(Str()   $key) { self!keys.contains($key) }
}

multi sub postcircumfix:<{ }>(Map::Match:D $map,
  \keys,
  :$exists,
  :$p,
  :$k,
  :$v
) is export {
    my &mapper := $map.mapper($exists, $p, $k);
    if keys ~~ Iterable {
        my $found := IterationBuffer.CREATE;
        my $iterator := keys.iterator;
        my $key;

        until ($key := $iterator.pull-one) =:= IterationEnd {
            $found.append: $map.lookup($key, &mapper)
        }

        $found.Slip
    }
    else {
        $map.lookup(keys, &mapper).Slip
    }
}

=begin pod

=head1 NAME

Map::Match - Provide a Map where keys are regular expressions

=head1 SYNOPSIS

=begin code :lang<raku>

use Map::Match;

my %m is Map::Match = foo => 42, b16ar => 666, baz18 => 137;

.say for %m<a>;  # 666␤137␤, same as / a /

.say for %m{ / \d >> / };    # 137␤

.say for %m{ / \d >> / }:k;  # baz18␤

=end code

=head1 DESCRIPTION

Map::Match provides an implementation of the C<Map> interface where key values
are interpreted as regular expressions.  This has the following implications
with regards to the normal behaviour of C<Map>s:

=head2 CAN RETURN MORE THAN ONE

Since a regular expression can match multiple times, you can receive more than
one value back from a single key.  Therefore, a C<Slip> will always be returned
as the value.

=head2 ALWAYS A SLIP

The value returned from any C<Map> access is B<always> a C<Slip>, albeit
potentially empty.  This is different from a normal C<Map> where C<Nil> would
be returned when specifying a key that does not exist in the C<Map>.

=head2 NON-REGEX KEY ASSUMED TO BE REGEX

If you specify a C<Str> as a key, or something that can be coerced to a C<Str>,
it will be interpreted as being interpolated in a C<Regex> with C<:ignorecase>
and C<:ignoremark> enabled.

=head1 AUTHOR

Elizabeth Mattijsen <liz@wenzperl.nl>

Source can be located at: https://github.com/lizmat/Map-Match . Comments and
Pull Requests are welcome.

=head1 COPYRIGHT AND LICENSE

Copyright 2021, 2022 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

# vim: expandtab shiftwidth=4
