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

my $header = <<'END_OF_TEXT';
<!doctype html>
<html dir="rtl" lang="ar">
<head>
<meta charset="utf-8">
<title>معجم يسمو</title>
<link rel="stylesheet" type="text/css" href="style.css">
</head>
<body>
END_OF_TEXT

my $footer = <<'END_OF_TEXT';
<div class="footer">
  <!--experimental-->
  <p>يمكنك التواصل معنا عبر
    صفحة <a href="https://github.com/noureddin/ysmu/issues">مسائل GitHub</a><br>
    أو غرفة الترجمة في مجتمع أسس على شبكة ماتركس: <a dir="ltr" href="https://matrix.to/#/#localization:aosus.org">#localization:aosus.org</a>
  </p>
</div>
</body>
</html>
END_OF_TEXT

sub make_entry { my ($file, $out_html, $out_tsv) = @_;
  my $link = $file =~ s,^.*/,,r;
  my $title = $link =~ s,_, ,gr;
  my $html = filepath_to_html $file;
  say { $out_html } qq[<h2 id="$link"><a href="#$link">$title</a></h2>\n$html];
  say { $out_tsv } $title, "\t", html_to_summary $html  if $out_tsv;
}

# we generate three files:
#   index.html, which contains the stable entries (in w/*)
#   ysmu.tsv, which summarizes the stable entries (in w/*)
#   experimental/index.html, which contains the experimental entries (in x/*)

# we start with the stable entries

open my $index, '>', 'index.html';
open my $summary, '>', 'ysmu.tsv';

print { $index } $header;

my $words;

for my $term (<w/*>) {
  ++$words;
  make_entry($term, $index, $summary);
}

my $goto_experimental = '<p>يمكنك أيضا رؤية <a href="experimental">المصطلحات التجريبية</a>.</p>';

if (!$words) {
  say { $index } '<div class="emptypage">لا توجد مصطلحات مستقرة بعد.</div>';
  $goto_experimental =~ s/أيضا//;
}

say { $index } $footer
  =~ s|<!--experimental-->|$goto_experimental|r
  ;

close $index;
close $summary;

# now the experimental entries

open my $exper, '>', 'experimental/index.html';

print { $exper } $header
  =~ s,(?=</title>), — المصطلحات التجريبية,r
  =~ s,(?<=href=")(?=style.css"),../,r
  ;

print { $exper } <<'END_OF_TEXT';
<div class="alert">
  <strong>تنبيه:</strong>
  هذه المصطلحات تجريبية؛ انظر
  <a href="..">المصطلحات المستقرة</a>.
</div>
END_OF_TEXT

my $xwords;
for my $term (<x/*>) {
  ++$xwords;
  make_entry($term, $exper);
}

if (!$xwords) {
  say { $exper } '<div class="emptypage">لا توجد مصطلحات تجريبية حاليا.</div>';
}

say { $exper } $footer
  =~ s| *<!--experimental--> *\n||r
  ;

close $exper;

