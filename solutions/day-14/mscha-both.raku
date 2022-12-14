#!/usr/bin/env raku
use v6.d;
$*OUT.out-buffer = False;   # Autoflush

# Advent of Code 2022 day 14
# https://adventofcode.com/2022/day/14
# https://github.com/mscha/aoc

class Position
{
    has Int $.x;
    has Int $.y;

    method WHICH() { ValueObjAt.new("Position|$!x|$!y") }   # Value type

    method Str { "($!x,$!y)" }
    method gist { self.Str }

    multi method to(Position $end where $end.x == $!x) { ($!y ... $end.y).map({ pos($!x, $^y) }) }
    multi method to(Position $end where $end.y == $!y) { ($!x ... $end.x).map({ pos($^x, $!y) }) }

    method S { pos($!x, $!y+1) }
    method SW { pos($!x-1, $!y+1) }
    method SE { pos($!x+1, $!y+1) }
    method downwards { self.S, self.SW, self.SE }
}

sub pos(Int() $x, Int() $y) { Position.new(:$x, :$y) }
multi sub infix:<==>(Position $a, Position $b) { $a.x == $b.x && $a.y == $b.y }
multi sub infix:<..>(Position $a, Position $b) { $a.to($b) }

class Cave
{
    has Position $.source = pos(500,0);     # Source of sand
    has Int $.floor-level = 1_000_000;      # Default: basically infinite

    has Int $.sand-dropped = 0;             # Number of units of sand dropped
    has Bool $.overflow = False;            # Has overflow happened?

    has @!grid;
    has Position $!min = $!source;
    has Position $!max = $!source;

    constant BLANK = '░';
    constant WALL = '▓';
    constant SOURCE = '+';
    constant SAND = 'o';

    submethod TWEAK
    {
        @!grid[$!source.y;$!source.x] = SOURCE;
    }

    method at(Position $p)
    {
        return WALL if $p.y ≥ $!floor-level;    # Floor is equivalent to wall
        return @!grid[$p.y;$p.x] // BLANK;      # Points outside known grid are blank
    }

    multi method set(Position $p, Str $val)
    {
        # Store the value in the right position in the grid
        @!grid[$p.y;$p.x] = $val;

        # Extend the boundaries of the grid, if necessary
        if $p.x > $!max.x || $p.y > $!max.y {
            $!max = pos(max($!max.x, $p.x), max($!max.y, $p.y));
        }
        if $p.x < $!min.x || $p.y < $!min.y {
            $!min = pos(min($!min.x, $p.x), min($!min.y, $p.y));
        }
    }
    multi method set(@p, $val) { self.set($_, $val) for @p }

    method draw-path(Str $path, Str $val = WALL)
    {
        # Draw a line for each segment in the path
        for $path.comb(/\d+/).rotor(4 => -2) -> ($x1,$y1, $x2,$y2) {
            self.set(pos($x1,$y1) .. pos($x2,$y2), $val);
        }
    }

    method set-floor-level(Int $delta)
    {
        # Set floor level
        $!floor-level = $!max.y + $delta;

        # We can't drop to floor level or below
        $!max = pos($!max.x, $!floor-level - 1);

        # Reset the overflow flag
        $!overflow = False;
    }

    method drop-sand
    {
        my $p = $!source;
        DROP:
        loop {
            # Drop to the first downward position that is available
            if my $q = $p.downwards.first({ self.at($^q) eq BLANK }) {
                $p = $q;
            }
            else {
                # No position available, stop dropping
                last DROP;
            }

            # Check for overflow
            if $p.y > $!max.y {
                $!overflow = True;
                return;
            }
        }

        # Add sand to the grid in the final position
        self.set($p, SAND);
        $!sand-dropped++;

        # We're also overflowing if there's nowhere to go from the source
        $!overflow = True if $p == $!source;
    }

    method Str
    {
        return (0 .. $!max.y+1).map(-> $y {
            (pos($!min.x-1, $y) .. pos($!max.x+1, $y)).map({ self.at($^p) }).join;
        }).join("\n");
    }
    method gist { self.Str }
}

sub MAIN(IO() $inputfile where *.f = 'aoc14.input', Bool :v(:$verbose) = False)
{
    my $cave = Cave.new;
    $cave.draw-path($_) for $inputfile.lines;
    say $cave if $verbose;
    until $cave.overflow {
        $cave.drop-sand;
        say "(sand dropped: $cave.sand-dropped())" if $verbose;
        say $cave if $verbose;
    }
    say "Part 1: ", $cave.sand-dropped;

    $cave.set-floor-level(2);
    until $cave.overflow {
        $cave.drop-sand;
        say "(sand dropped: $cave.sand-dropped())" if $verbose;
        say $cave if $verbose;
    }
    say "Part 2: ", $cave.sand-dropped;
}
