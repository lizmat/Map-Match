use Map::Agnostic:ver<0.0.10>:auth<zef:lizmat>;

class Map::Match does Map::Agnostic {
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
    multi method lookup(Regex:D $finder, &mapper) is implementation-detail {

        # Hack to spot usage of ^ and $ anchors in the regex.  If found,
        # remove them and use adapted regex for initial search, and then
        # verify
        my $string  = $finder.gist;
        my $verify = False;
        if $string.contains('^') {
            $string .= subst('^');
            $verify = True;
        }
        if $string.contains('$') {
            $string .= subst('$');
            $verify = True;
        }
        my $regex := $verify
          ?? $string.EVAL
          !! $finder;

        my $found := IterationBuffer.CREATE;
        my $keys  := self!keys;

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

            unless $key.contains("\0") {  # did not bleed into another key

                # add key, possibly after verification
                $found.push: mapper(%!map, $key)
                  unless $verify && !$key.contains($finder);
            }

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

    multi method CALL-ME(Map::Match:D:
      \keys, :$exists, :$p, :$k, :$v
    ) {
        my &mapper := self.mapper($exists, $p, $k);
        if keys ~~ Iterable {
            my $found := IterationBuffer.CREATE;
            my $iterator := keys.iterator;
            my $key;

            until ($key := $iterator.pull-one) =:= IterationEnd {
                $found.append: self.lookup($key, &mapper)
            }

            $found.Slip
        }
        else {
            self.lookup(keys, &mapper).Slip
        }
    }
}

multi sub postcircumfix:<{ }>(Map::Match:D $map, \keys, *%_) is export {
    $map.CALL-ME(keys, |%_)
}

# vim: expandtab shiftwidth=4
