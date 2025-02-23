#!/usr/bin/env perl
use v5.14; use warnings; use autodie; use utf8;
use open qw[ :encoding(UTF-8) :std ];

open my $fileread, '<', $ARGV[0];
my @t = map {
  # trim lines and collapse spaces
  s/^\s+//g;
  s/\s+$//g;
  s/  +/ /g;
  s/\t\t+/\t/g;
  s/\t +/\t/g;
  s/ +\t/\t/g;
  # convert spaces to underscores
  s/ /_/g;
  # return
  $_
} <$fileread>;
close $fileread;

# assert exactly one tab in each line, no more, no less; or the line is empty
if (my @multitab = grep /^.*\t.*\t.*$/, @t) {
  die "\e[31;1msome lines have more than one tab:\e[m\n",
    map { s/_/ /g; "  $_\n" } @multitab
}
if (my @notab = grep /^[^\t]+$/, @t) {
  die "\e[31;1msome lines have non-tab characters without a single tab:\e[m\n",
    map { s/_/ /g; "  $_\n" } @notab
}

# sort ASCIIbetically by the last word, ignoring case
@t =
  map { $_->[1] }
  sort { uc $a->[0] cmp uc $b->[0] || uc $a->[1] cmp uc $b->[1] }
  map { [s/.*?([^\t_]+)$/$1/r, $_] } @t;
  # last word (before the underscore), then short name

open my $filewrite, '>', $ARGV[0];
print { $filewrite } "$_\n" for @t;
close $filewrite;
