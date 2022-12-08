#!/usr/bin/raku

my @pairs = $*IN.lines>>.split(',')>>.split('-').cache;
say +@pairs.map({ [Z<=>] $_ }).grep(none((More, More), (Less, Less)));