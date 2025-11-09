#!/usr/bin/env perl
package Terms;
use v5.16; use warnings; use utf8;
use open qw[ :encoding(UTF-8) :std ];

use List::Util qw[ uniq ];

use parent 'Exporter';
our @EXPORT_OK = qw[
  get_terms
  get_links
];

use Parser qw[
  parse_entry
];

my %terms = map {
  my $file = $_;
  my ($cat, $base) = split '/';
  my ($t, $alt, $short) = split ',', $base;
  #
  my ($title) = ($t . ($alt ? ', '.$alt : "") . ($short ? ' ('.$short.')' : "")) =~ s/_/ /gr;
  $title =~ s/-(?=$|\P{Letter})/\N{EN DASH}/g;  # for prefixes
  my @terms = grep { $_ } ($t, $alt, $short);
  my @allterms = uniq map { $_, lc } @terms;
  #
  my $stage = $cat eq 'w' ? ''
            : $cat eq 'c' ? 'candidate/'
            : $cat eq 'x' ? 'experimental/'
            : $cat eq 'u' ? 'unstaged/'
              : die "\e[1;31m  bad stage for '$cat/' for '$base'\e[m\n";
  #
  $t => { file => $file, cat => $cat, alt => $alt, short => $short, terms => \@terms, allterms => \@allterms, title => $title, stage => $stage }
} glob '[wcxu]/*';

# TODO: check if any duplicate terms

# for each term, we generate a link in link/TERM/ that redirects to it in
# the agreed-upon, candidate, experimental, or unstaged page,
# in that order, so it's easier to link to term before they're stabilized.
my %links = map {
  my $t = $_;
  map { $_ => $t } @{$terms{$t}{allterms}}
} keys %terms;

%terms = map {
  my $id = $_;
  my $file = $terms{$_}{file};
  my ($html, $summary) = parse_entry($file);
  $html =~ s/<<title_of:([^<>]+)>>/exists $links{$1} ? $terms{$links{$1}}{title} : $1/ge;  # a warning is generated later, in .p/build
  #
  my @spellings;
  if ($html =~ /<p>####<br>\n(.*?)<\/p>/s) {
    @spellings = split "<br>\n", $1;
    $html =~ s/\s*<p>####<br>.*?<\/p>\s*//s;
  }
  #
  my $a = join "", map qq[<span class="anch" id="$_">], @{$terms{$id}{allterms}};
  my $b = join "", map qq[</span>], @{$terms{$id}{allterms}};
  my $entry = qq[<hr class="rm"><article>$a<h2><a dir="ltr" href="#$id">$terms{$id}{title}</a></h2>$b\n$html\n</article>];
  #
  $id => { %{$terms{$id}}, spellings => \@spellings, entry => $entry, summary => $summary }
} keys %terms;

# say $terms{$_}{cat}.': '.join(", ", @{$terms{$_}{allterms}})
#   for sort keys %terms;

# say $terms{$_}{cat}.': '.$terms{$_}{title}
#   for sort keys %terms;

sub get_terms() { return %terms }
sub get_links() { return %links }

1;
