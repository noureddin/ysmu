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
use BigParser;

use constant HEADER => <<'END_OF_TEXT';
<!doctype html>
<html dir="rtl" lang="ar">
<head>
<meta charset="utf-8">
<title>معجم يسمو</title>
<link rel="stylesheet" type="text/css" href="style.css">
</head>
<body>
END_OF_TEXT

sub make_header { my ($additional_title) = @_;
  my $desc = $additional_title ? ' — '.$additional_title : ' للمصطلحات التقنية الحديثة';
  my $root = $additional_title ? '../' : '';
  return HEADER
    =~ s,(?=</title>),$desc,r
    =~ s,(?<=href=")(?=style.css"),$root,r
    =~ s,\n\Z,,r  # to use say with almost everything
}

use constant FOOTER => <<'END_OF_TEXT' =~ s,\n\Z,,r;  # to use say with almost everything
<div class="footer">
  <!--before-contact-->
  <p>يمكنك التواصل معنا عبر
    صفحة <a href="https://github.com/noureddin/ysmu/issues/">مسائل GitHub</a><br>
    أو غرفة الترجمة في مجتمع أسس على شبكة ماتركس: <a dir="ltr" href="https://matrix.to/#/#localization:aosus.org">#localization:aosus.org</a>
  </p>
  <!--before-license-->
  <p class="blurred">الرخصة: <a href="https://creativecommons.org/choose/zero/">Creative Commons Zero (CC0)</a> (مكافئة للملكية العامة)</p>
</div>
</body>
</html>
END_OF_TEXT

sub notes_link  { '<a href="'.($_[0] // '').'notes/">موارد وإرشادات</a>' }
sub exper_link  { '<a href="'.($_[0] // '').'experimental/">المصطلحات التجريبية</a>' }
sub stable_link { '<a href="..">المصطلحات المستقرة</a>' }

sub make_footer { my ($s) = @_;
  if ($s eq 'stable') {
    return FOOTER
      =~ s|<!--before-contact-->|<p>يمكنك أيضا رؤية @{[ exper_link ]}</p>|r
      =~ s| *<!--before-license--> *\n||r
  }
  elsif ($s eq 'empty stable') {
    return FOOTER
      =~ s|<!--before-contact-->|<p>يمكنك رؤية @{[ exper_link ]}</p>|r
      =~ s| *<!--before-license--> *\n||r
  }
  elsif ($s eq 'experimental' || $s eq 'empty experimental') {
    return FOOTER
      =~ s| *<!--before-contact--> *\n||r
      =~ s|<!--before-license-->|<p class="blurred">انظر أيضا: @{[ notes_link '../' ]}</p>|r
  }
  elsif ($s eq 'notes') {
    return FOOTER
      =~ s|<!--before-contact-->|<p>يمكنك رؤية @{[ stable_link ]} أو @{[ exper_link '../' ]}</p>|r
      =~ s| *<!--before-license--> *\n||r
  }
  else {
    die "make_footer received wrong argument: '$s'\n"
  }
}

sub _make_entry { my ($file) = @_;
  my $id = $file =~ s,^.*/,,r;
  my $title = $id =~ s,_, ,gr;
  my $html = filepath_to_html $file;
  my $link = qq[<a dir="ltr" href="#$id">$title</a>];
  return (
    link => $link,
    entry => qq[<h2 id="$id">$link</h2>\n$html],
    summary => (join "\t", $title, html_to_summary $html),
  );
}

sub make_entries { my ($out_html, $out_tsv) = (shift, shift);
  my $n = 0;
  my $toc = '';
  my $body = '';
  my $summary = '';
  for my $file (@_) {
    ++$n;
    my %e = _make_entry($file);
    $toc .= $e{link}."\n";
    $body .= $e{entry}."\n";
    $summary .= $e{summary}."\n"  if $out_tsv;
  }
  $toc = $toc ? qq[<div class="toc">\n$toc</div>\n] : '';
  print { $out_html } $toc.$body;
  print { $out_tsv } $summary  if $out_tsv;
  return $n;
}

# we generate four files:
#   index.html, which contains the stable entries (in w/*)
#   ysmu.tsv, which summarizes the stable entries (in w/*)
#   experimental/index.html, which contains the experimental entries (in x/*)
#   notes/index.html from notes/src, which is general prose

# we start with the stable entries

open my $index, '>', 'index.html';
open my $summary, '>', 'ysmu.tsv';

say { $index } make_header;

if (make_entries($index, $summary, <w/*>)) {  # non-empty
  say { $index } make_footer 'stable';
}
else {  # empty
  say { $index } '<div class="emptypage">لا توجد مصطلحات مستقرة بعد.</div>';
  say { $index } make_footer 'empty stable';
}

close $index;
close $summary;

# now the experimental entries

open my $exper, '>', 'experimental/index.html';

say { $exper } make_header 'المصطلحات التجريبية';

print { $exper } <<"END_OF_TEXT";
<div class="alert">
  <strong>تنبيه:</strong>
  هذه المصطلحات تجريبية؛ انظر
  @{[ stable_link ]}.
</div>
END_OF_TEXT

if (make_entries($exper, undef, <x/*>)) {  # non-empty
  say { $exper } make_footer 'experimental';
}
else {
  say { $exper } '<div class="emptypage">لا توجد مصطلحات تجريبية حاليا.</div>';
  say { $exper } make_footer 'empty experimental';
}

close $exper;

# and then the notes

open my $notes, '>', 'notes/index.html';

say { $notes } make_header 'موارد وإرشادات';

say { $notes } basic_html_to_big_html filepath_to_html 'notes/src';

say { $notes } make_footer 'notes';

close $notes;

