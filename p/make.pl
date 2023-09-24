#!/usr/bin/env perl
use v5.14; use warnings; use autodie; use utf8;
use open qw[ :encoding(UTF-8) :std ];

use FindBin;
# allow loading our libraries from the script's directory
use lib $FindBin::RealBin;
# change to the repo's root, regardless where we're called from.
chdir "$FindBin::RealBin/../";

# load our libraries
use Parser;

my $header = <<~'END_OF_TEXT';
  <!doctype html>
  <html dir="rtl" lang="ar">
  <head>
  <meta charset="utf-8">
  <title>معجم يسمو</title>
  <link rel="stylesheet" type="text/css" href=".style.css">
  </head>
  <body>
END_OF_TEXT

my $footer = <<~'END_OF_TEXT';
  </body>
  </html>
END_OF_TEXT

sub term_to_header(_) { my ($term) = @_;
  $term =~ s,^.*/,,;
  return qq[<h2 id="$term"><a href="#$term">@{[ $term =~ s/_/ /gr ]}</a></h2>];
}

# we generate three files:
#   index.html, which contains the stable entries (in w/*)
#   ysmu.tsv, which summarizes the stable entries (in w/*)
#   experimental/index.html, which contains the experimental entries (in x/*)

# we start with the stable entries

open my $index, '>', 'index.html';
open my $summary, '>', 'ysmu.tsv';

say { $index } $header;

for my $term (<w/*>) {
  my $html = filepath_to_html $term;
  say { $index } term_to_header $term;
  say { $index } $html;
  say { $summary } $term, "\t", html_to_summary $html;
}

say { $index } $footer;

close $index;
close $summary;

# now the experimental entries

open my $exper, '>', 'experimental/index.html';

say { $exper } $header =~ s,(?<=href=")(?=[.]style.css"),../,r;

say { $exper } <<~'END_OF_TEXT';
  <div class="experimental-alert" align="center">
    <strong>تنبيه:</strong>
    هذه الترجمات تجريبية؛ انظر
    <a href="..">النسخة المستقرة من المعجم</a>.
  </div align="center">
END_OF_TEXT

for my $term (<x/*>) {
  say { $exper } term_to_header $term;
  say { $exper } filepath_to_html $term;
}

say { $exper } $footer;

close $exper;

