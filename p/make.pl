#!/usr/bin/env perl
use v5.14; use warnings; use autodie; use utf8;
use open qw[ :encoding(UTF-8) :std ];

use FindBin;
# allow loading our libraries from the script's directory
use lib $FindBin::RealBin;
# change to the repo's root, regardless where we're called from.
chdir "$FindBin::RealBin/../";

# load our libraries

use Parser qw[
  filepath_to_html
  html_to_summary
  title_of
  acronym_title_of
];

use BigParser qw[
  basic_html_to_big_html
];
# a single function that reads the output of Parser's filepath_to_html on a big file

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

sub make_header { my ($additional_title, $base) = @_;
  my $root = $base ? $base :
             $additional_title ? '../' : '';
  my $desc = $additional_title ? ' — '.$additional_title : ' للمصطلحات التقنية الحديثة';
  return HEADER
    =~ s,(?=</title>),$desc,r
    =~ s,(?<=href=")(?=style.css"),$root,r
    =~ s,\n\Z,,r  # to use say with almost everything
    # ensure proper text direction for the page's title
    =~ s,(?<=<title>),\N{RIGHT-TO-LEFT EMBEDDING},r
    =~ s,(?=</title>),\N{POP DIRECTIONAL FORMATTING},r
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
sub rc_link     { '<a href="'.($_[0] // '').'candidate/">المصطلحات المرشحة للاتفاق</a>' }
sub exper_link  { '<a href="'.($_[0] // '').'experimental/">المصطلحات التجريبية</a>' }
sub stable_link { '<a href="..">المصطلحات المتفق عليها</a>' }

sub make_footer { my ($s) = @_;
  if ($s eq 'stable') {
    return FOOTER
      =~ s|<!--before-contact-->|<p>يمكنك أيضا رؤية @{[ rc_link ]}</p>|r
      =~ s| *<!--before-license--> *\n||r
  }
  elsif ($s eq 'empty stable') {
    return FOOTER
      =~ s|<!--before-contact-->|<p>يمكنك رؤية @{[ rc_link ]}</p>|r
      =~ s| *<!--before-license--> *\n||r
  }
  elsif ($s eq 'candidate') {
    return FOOTER
      =~ s|<!--before-contact-->|<p>يمكنك أيضا رؤية @{[ exper_link '../' ]}</p>|r
      =~ s| *<!--before-license--> *\n||r
  }
  elsif ($s eq 'empty candidate') {
    return FOOTER
      =~ s|<!--before-contact-->|<p>يمكنك رؤية @{[ exper_link '../' ]}</p>|r
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
  elsif ($s eq 'link' || $s eq 'empty unstaged' || $s eq 'unstaged') {
    return FOOTER
      =~ s| *<!--before-contact--> *\n||r
      =~ s| *<!--before-license--> *\n||r
  }
  else {
    die "\e[1;31m  make_footer received wrong argument: '$s'\e[m\n"
  }
}

my %long =
  map {
    # if this line contains exactly one tab, with entries on both sides
    /^[^\t]+\t[^\t]+$/ ? split "\t" : ()
  }
  map { s,[ \r\n]+,,gr }  # spaces are not allowed; use underscores between words
  do { open my $fh, '<', 'longnames.tsv'; <$fh> };  # read as an array of lines

my %short = reverse %long;

sub long_title_of(_) { my ($id) = @_;
  my $ttl = title_of($long{$id});
  my $acr = acronym_title_of($id);
  return "$ttl ($acr)";
}

sub human_title_of(_) { my ($id) = @_;
  $id = $id =~ s,^\s*,,r =~ s,\s*$,,r =~ s,\s+,_,gr;
  if (exists $long{$id}) {
    return long_title_of($id)
  }
  elsif (exists $short{$id}) {
    return long_title_of($short{$id});
  }
  else {
    return title_of($id);
  }
}

# for each term, we generate a link in link/TERM/ that redirects to it in
# the agreed-upon page, or in the candidate page, or in the experimental page,
# in that order, so it's easier to link to term before it's stabilized.
my %links;

sub _make_entry { my ($file) = @_;
  my $id = $file =~ s,^.*/,,r;
  my $h_id = qq[ id="$id"];  # assumption for short_ids: file names are always the short
  my $a_id = exists $long{$id} ? qq[ id="$long{$id}"] : '';
  my $title = human_title_of($id);
  my $html = filepath_to_html $file, \&human_title_of;
  $links{$id} = $file =~ s,/.*,,r unless exists $links{$id};
  return (
    link => qq[<a dir="ltr" href="#$id">$title</a>],
    entry => qq[<h2$h_id><a$a_id dir="ltr" href="#$id">$title</a></h2>\n$html],
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
  my $parent = !defined $_[0]   ? undef : ($_[0] =~ s,/.*,,r);
  my $root   = !defined $parent ? undef : $parent eq 'w' ? '' : '..';
  my @links = ($body =~ /<a\b[^>]* href="#([^"]*)"/g);
  for my $term (@links) {
    if (!-f "$parent/$term") {  # not in this stage; make it a /link/
      $body =~ s,(<a\b[^>]* href=")#$term",$1$root/link/$term/",g
    }
  }
  print { $out_html } $toc.$body;
  print { $out_tsv } $summary  if $out_tsv;
  return $n;
}

# we generate these files (in addition to the links mentioned above):
#   index.html, which contains the agreed-upon entries (in w/*)
#   ysmu.tsv, which summarizes the agreed-upon entries (in w/*)
#   candidate/index.html, which contains the "release candidate" entries (in c/*)
#   experimental/index.html, which contains the experimental entries (in x/*)
#   unstaged/index.html, which contains the unstaged entries (in u/*)
#   notes/index.html from notes/src, which is general prose
#   link/index.html, which is an index of all terms in the four stages.

# we start with the stable entries

open my $index, '>', 'index.html';
open my $summary, '>', 'ysmu.tsv';

say { $index } make_header;

if (make_entries($index, $summary, <w/*>)) {  # if non-empty
  say { $index } make_footer 'stable';
}
else {  # if empty
  say { $index } '<div class="emptypage">لا توجد مصطلحات متفق عليها بعد</div>';
  say { $index } make_footer 'empty stable';
}

close $index;
close $summary;

# all other stages have an identical structure

sub make_stage { my ($words_dir, $name, $title, $alert, $emptymsg) = @_;
  mkdir $name unless -d $name;
  open my $fh, '>', $name.'/index.html';
  #
  say { $fh } make_header $title;
  #
  print { $fh } <<~"END_OF_TEXT" if $alert;
  <div class="alert">
    <strong>تنبيه:</strong>
    $alert؛
    انظر @{[ stable_link ]}
  </div>
  END_OF_TEXT
  #
  if (make_entries($fh, undef, <$words_dir/*>)) {  # if non-empty
    say { $fh } make_footer $name;
  }
  else {  # if empty
    say { $fh } qq[<div class="emptypage">$emptymsg</div>];
    say { $fh } make_footer "empty $name";
  }
  #
  close $fh;
}

sub make_page { my ($name, $header, $content, $footername) = @_;
  $footername //= $name =~ s,/.*,,r;
  mkdir $name unless -d $name;
  open my $fh, '>', $name.'/index.html';
  say { $fh } $header ;
  say { $fh } $content;
  say { $fh } make_footer $footername;
  close $fh;
}

#################################################

make_stage 'c', 'candidate', 'المصطلحات المرشحة للاتفاق',
  'هذه المصطلحات مرشحة للاتفاق لكن غير متفق عليها بعد',
  'لا توجد مصطلحات مرشحة حاليا';

make_stage 'x', 'experimental', 'المصطلحات التجريبية',
  'هذه المصطلحات تجريبية ولم تُناقش في المجتمع بعد',
  'لا توجد مصطلحات تجريبية حاليا';

make_stage 'u', 'unstaged', 'المصطلحات المؤجلة',
  'هذه المصطلحات مؤجلة، فليست حتى معروضة للنقاش في المجتمع',
  'لا توجد مصطلحات مؤجلة حاليا';

make_page 'notes',
  make_header('موارد وإرشادات'),
  basic_html_to_big_html(filepath_to_html 'notes/src');

# and finally the links...

use File::Path qw[ remove_tree ];
remove_tree 'link' if -d 'link';
mkdir 'link';

use constant ROOT_FOR_LINKS => '../../';
sub make_link { my ($id, $title, $parent) = @_;
  my $url = join '', ROOT_FOR_LINKS, $parent, '#', $id;
  #
  make_page "link/$id",
    make_header("توجيه إلى \N{LEFT-TO-RIGHT EMBEDDING}$title\N{POP DIRECTIONAL FORMATTING} آليا", ROOT_FOR_LINKS)
      =~ s,\n</head>,<meta http-equiv="Refresh" content="0; url=$url" />$&,r,
    qq[<center>ستوجه الآن إلى <a dir="rtl" href="$url">$title</a> آليا<br>(اضغط على الرابط أعلاه إن لم توجه)</center>];
}

for my $id (keys %links) {
  my $parent = $links{$id} eq 'w' ? ''
             : $links{$id} eq 'c' ? 'candidate/'
             : $links{$id} eq 'x' ? 'experimental/'
             : $links{$id} eq 'u' ? 'unstaged/'
             : die "\e[1;31m  bad parent for '$id' in link/\e[m\n";
  if (exists $long{$id}) {  # if $id is an acronym
    make_link $id, acronym_title_of($id), $parent;
    make_link $long{$id}, title_of($long{$id}), $parent;
  }
  else {
    make_link $id, title_of($id), $parent;
  }
}

# ...and the links index

use constant EMPTY_STAGE_LINKS => qq[  <center class="blurred">لا توجد مصطلحات في هذه المرحلة</center>];

make_page 'link',
  make_header('روابط جميع المصطلحات'),
  do {
    my ($w, $c, $x, $u) = ('') x 4;
    for my $id (sort keys %links) {
      my $title = human_title_of($id);
      my $link = qq[  <a dir="ltr" href="$id">$title</a>\n];
      if    ($links{$id} eq 'w') { $w .= $link }
      elsif ($links{$id} eq 'c') { $c .= $link }
      elsif ($links{$id} eq 'x') { $x .= $link }
      elsif ($links{$id} eq 'u') { $u .= $link }
      else { die "\e[1;31m  bad parent for '$id' in link/\e[m\n"; }
    }
    # if empty say so, otherwise enclose in div.toc 
    $w = $w eq '' ? EMPTY_STAGE_LINKS : qq[<div class="toc">\n] . $w . qq[</div>];
    $c = $c eq '' ? EMPTY_STAGE_LINKS : qq[<div class="toc">\n] . $c . qq[</div>];
    $x = $x eq '' ? EMPTY_STAGE_LINKS : qq[<div class="toc">\n] . $x . qq[</div>];
    $u = $u eq '' ? EMPTY_STAGE_LINKS : qq[<div class="toc">\n] . $u . qq[</div>];
    # return
    sprintf qq[<h2 id="%s"><a href="#%s">%s</a></h2>\n%s%s] x 4,
      ('agreed')x2,       'المصطلحات المتفق عليها',     $w, "\n",
      ('candidate')x2,    'المصطلحات المرشحة للاتفاق',  $c, "\n",
      ('experimental')x2, 'المصطلحات التجريبية',        $x, "\n",
      ('unstaged')x2,     'المصطلحات المؤجلة',          $u, ""
  };

