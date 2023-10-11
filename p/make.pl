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
  word_title_of
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
  <title>{{title}}</title>
  <link rel="stylesheet" type="text/css" href="style.css">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta property="og:locale" content="ar_AR">
  <meta property="og:type" content="website">
  <meta property="og:title" content="{{title}}">
  <link rel="canonical" href="{{url}}">
  <meta property="og:url" content="{{url}}">
</head>
<body>
END_OF_TEXT

sub make_header { my ($additional_title, $path, $base) = @_;
  $path //= '';
  my $root = $base ? $base :
             $additional_title ? '../' : '';
  my $desc = $additional_title ? ' — '.$additional_title : ' للمصطلحات التقنية الحديثة';
  my $url  = "https://noureddin.github.io/ysmu/$path/" =~ s,/+$,/,r;

  return HEADER
    =~ s,\Q{{title}}\E,معجم يسمو$desc,gr
    =~ s,\Q{{url}}\E,$url,gr
    =~ s,(?<=href=")(?=style.css"),$root,r
    =~ s,\n\Z,,r  # to use say with almost everything
    # ensure proper text direction for the page's title (TODO: only for <title> and not meta og:title?)
    =~ s,(?<=<title>),\N{RIGHT-TO-LEFT EMBEDDING},r
    =~ s,(?=</title>),\N{POP DIRECTIONAL FORMATTING},r
}

use constant FOOTER => <<'END_OF_TEXT' =~ s,\n\Z,,r;  # to use say with almost everything
<div class="footer">
  <!--before-contact-->
  <p>يمكنك التواصل معنا عبر
    صفحة <a target="_blank" rel="author" href="https://github.com/noureddin/ysmu/issues/">مسائل GitHub</a><br>
    أو غرفة الترجمة في مجتمع أسس على شبكة ماتركس: <a target="_blank" dir="ltr" href="https://matrix.to/#/#localization:aosus.org">#localization:aosus.org</a>
  </p>
  <!--before-license-->
  <p class="blurred">الرخصة: <a target="_blank" rel="license" href="https://creativecommons.org/choose/zero/">Creative Commons Zero (CC0)</a> (مكافئة للملكية العامة)</p>
</div>
</body>
</html>
END_OF_TEXT

use constant SINGLE_FILTERING_SCRIPT => <<'END_OF_TEXT';
<script>
  function normalize_text (t) {  // for filtering
    return t.toLowerCase().replace(/[-_\s]+/g, ' ').replace(/^ /g, '').replace(/ $/g, ' ')
    // .trim() is introduced in 2010; .replace() is introduced in 2000
  }
  function filter_terms (q) {
    // hide toc entries that aren't a substring of the input (q)
    var tocens = document.querySelectorAll('.toc > a')
    var nonempty = false
    for (var i = 0; i < tocens.length; ++i) {
      var a = tocens[i]
      // TODO: make spaces an "AND" operation instead of matching
      // TODO: search in the "see also" terms
      //       and in the terms mentioned in the entry's desc.
      a.className =
        normalize_text(a.textContent).indexOf(normalize_text(q)) === -1
          ? 'hidden'
          : ''
      if (a.className === '') { nonempty = true }
      // oldest .indexOf() instead of the 2015 .includes()
    }
    document.querySelector('.emptytoc').style.display = nonempty ? 'none' : 'block'
    // for & var & className instead of forEach & const & classList
    // to work on the oldest browsers (ignoring IE).
  }
  onload = filter_terms(document.getElementById('filter').value)
</script>
END_OF_TEXT

use constant MULTIPLE_FILTERING_SCRIPT => <<'END_OF_TEXT';
<script>
  function normalize_text (t) {  // for filtering
    return t.toLowerCase().replace(/[-_\s]+/g, ' ').replace(/^ /g, '').replace(/ $/g, ' ')
    // .trim() is introduced in 2010; .replace() is introduced in 2000
  }
  function filter_terms (q) {
    // hide toc entries that aren't a substring of the input (q)
    var tocens = document.querySelectorAll('.toc > a')
    for (var i = 0; i < tocens.length; ++i) {
      var a = tocens[i]
      // TODO: make spaces an "AND" operation instead of matching
      // TODO: search in the "see also" terms
      //       and in the terms mentioned in the entry's desc.
      a.className =
        normalize_text(a.textContent).indexOf(normalize_text(q)) === -1
          ? 'hidden'
          : ''
      // oldest .indexOf() instead of the 2015 .includes()
    }
    var tocs = document.querySelectorAll('.toc')
    for (var i = 0; i < tocs.length; ++i) {
      tocs[i].querySelector('.emptytoc').style.display =
        tocs[i].querySelector('a:not(.hidden)') == null
          ? 'block' : 'none'
    }
    // for & var & className instead of forEach & const & classList
    // to work on the oldest browsers (ignoring IE).
  }
  onload = filter_terms(document.getElementById('filter').value)
</script>
END_OF_TEXT

sub all_link    { '<a href="'.($_[0] // '').'link/">قائمة روابط جميع المصطلحات</a>' }
sub notes_link  { '<a href="'.($_[0] // '').'notes/">موارد وإرشادات</a>' }
sub rc_link     { '<a href="'.($_[0] // '').'candidate/">المصطلحات المرشحة للاتفاق</a>' }
sub exper_link  { '<a href="'.($_[0] // '').'experimental/">المصطلحات التجريبية</a>' }
sub tsv_link    { '<a href="https://github.com/noureddin/ysmu/raw/main/ysmu.tsv">ysmu.tsv</a>' }
sub stable_link { '<a href="..">المصطلحات المتفق عليها</a>' }

sub make_footer { my ($s) = @_;
  if ($s eq 'stable') {
    return FOOTER
      =~ s|<!--before-contact-->|<p>يمكنك أيضا رؤية @{[ rc_link ]}</p>|r
      =~ s|<!--before-license-->|<p class="blurred">الترجمة المختصرة بصيغة TSV للتطبيقات والمعاجم: @{[ tsv_link ]}</p>|r
      =~ s,(?=</body>),@{[ SINGLE_FILTERING_SCRIPT ]},r;
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
      =~ s,(?=</body>),@{[ SINGLE_FILTERING_SCRIPT ]},r;
  }
  elsif ($s eq 'empty candidate') {
    return FOOTER
      =~ s|<!--before-contact-->|<p>يمكنك رؤية @{[ exper_link '../' ]}</p>|r
      =~ s| *<!--before-license--> *\n||r
  }
  elsif ($s eq 'experimental') {
    return FOOTER
      =~ s| *<!--before-contact--> *\n||r
      =~ s|<!--before-license-->|<p class="blurred">انظر أيضا: @{[ notes_link '../' ]}</p>|r
      =~ s,(?=</body>),@{[ SINGLE_FILTERING_SCRIPT ]},r;
  }
  elsif ($s eq 'empty experimental') {
    return FOOTER
      =~ s| *<!--before-contact--> *\n||r
      =~ s|<!--before-license-->|<p class="blurred">انظر أيضا: @{[ notes_link '../' ]}</p>|r
  }
  elsif ($s eq 'unstaged') {
    return FOOTER
      =~ s| *<!--before-contact--> *\n||r
      =~ s| *<!--before-license--> *\n||r
      =~ s,(?=</body>),@{[ SINGLE_FILTERING_SCRIPT ]},r;
  }
  elsif ($s eq 'empty unstaged') {
    return FOOTER
      =~ s| *<!--before-contact--> *\n||r
      =~ s| *<!--before-license--> *\n||r
  }
  elsif ($s eq 'all') {
    return FOOTER
      =~ s| *<!--before-contact--> *\n||r
      =~ s| *<!--before-license--> *\n||r
      =~ s,(?=</body>),@{[ MULTIPLE_FILTERING_SCRIPT ]},r;
  }
  elsif ($s eq 'link') {
    return FOOTER
      =~ s| *<!--before-contact--> *\n||r
      =~ s| *<!--before-license--> *\n||r
  }
  elsif ($s eq 'notes') {
    return FOOTER
      # =~ s|<!--before-contact-->|<p>يمكنك رؤية @{[ stable_link ]} أو @{[ exper_link '../' ]}</p>|r
      =~ s|<!--before-contact-->|<p>يمكنك رؤية @{[ all_link '../' ]}</p>|r
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
  my $ttl = word_title_of($long{$id});
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
    return word_title_of($id);
  }
}

sub toc_links {  # array of [$title, "#$id"]; returns a string '<div class="toc">...<a href="#id">title</a>...</div>' (or undef if empty)
  if (@_) {
    return qq[<div class="toc">\n] . (
      join '',
        map { qq[  <a href="$_->[1]">$_->[0]</a>\n] }
        sort { $a->[0] cmp $b->[0] }
          @_
    ) . qq[  <div class="emptytoc blurred" style="display:none">لا توجد مصطلحات متطابقة</div>\n</div>];
  }
  return;  # undef if empty
}

# for each term, we generate a link in link/TERM/ that redirects to it in
# the agreed-upon page, or in the candidate page, or in the experimental page,
# in that order, so it's easier to link to term before it's stabilized.
my %links;

sub _make_entry { my ($file) = @_;
  my $id = $file =~ s,^.*/,,r;
  my $h_id = qq[ id="$id"];
  my $a_id = exists $long{$id} ? qq[ id="$long{$id}"] : '';
  my $title = human_title_of($id);
  my $html = filepath_to_html $file, \&human_title_of;
  $links{$id} = $file =~ s,/.*,,r unless exists $links{$id};
  # NOTE: files MUST use the short name
  return (
    toclinkpair => [ $title, '#'.$id ],
    entry => qq[<h2$h_id><a$a_id dir="ltr" href="#$id">$title</a></h2>\n$html],
    summary => (join "\t", $title, html_to_summary $html),
  );
}

use constant TOC_FILTER => sprintf "<input %s>\n", join ' ',
  'id="filter"', 'type="text"', 'dir="ltr"',
  'oninput="filter_terms(this.value)"',
  'placeholder="🔍 اكتب لتصفية روابط المصطلحات المعروضة"';

sub make_entries { my ($out_html, $out_tsv) = (shift, shift);
  my $n = 0;
  my @toc;
  my $body = '';
  my $summary = '';
  for my $file (@_) {
    ++$n;
    my %e = _make_entry($file);
    push @toc, $e{toclinkpair};
    $body .= $e{entry}."\n";
    $summary .= $e{summary}."\n"  if $out_tsv;
  }
  my $toc = toc_links(@toc) // '';
  my $parent = !defined $_[0]   ? undef : ($_[0] =~ s,/.*,,r);
  my $root   = !defined $parent ? undef : $parent eq 'w' ? '' : '..';
  my @links = ($body =~ /<a\b[^>]* href="#([^"]*)"/g);
  for my $term (@links) {
    if (!-f "$parent/$term") {  # not in this stage; make it a /link/
      $body =~ s,(<a\b[^>]* href=")#$term",$1$root/link/$term/",g
    }
  }
  print { $out_html } ($toc ? TOC_FILTER.$toc."\n" : '') . $body;
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
  say { $fh } make_header $title, $name;
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
  say { $fh } $header;
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
  make_header('موارد وإرشادات', 'notes'),
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
    make_header("توجيه إلى \N{LEFT-TO-RIGHT EMBEDDING}$title\N{POP DIRECTIONAL FORMATTING} آليا", "link/$id", ROOT_FOR_LINKS)
      =~ s,\n</head>,\n  <meta http-equiv="Refresh" content="0; url=$url">$&,r,
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
    make_link $long{$id}, word_title_of($long{$id}), $parent;
  }
  else {
    make_link $id, word_title_of($id), $parent;
  }
}

# ...and the links index

use constant EMPTY_STAGE_LINKS => qq[  <center class="blurred">لا توجد مصطلحات في هذه المرحلة حاليا</center>];

make_page 'link',
  make_header('روابط جميع المصطلحات', 'link'),
  do {
    my (@w, @c, @x, @u);
    for my $id (keys %links) {
      # %links sorting is not enough, b/c if an acronym exists it uses for sorting (consider 2FA).
      my $title = human_title_of($id);
      if    ($links{$id} eq 'w') { push @w, [ $title,              "../#$id" ] }
      elsif ($links{$id} eq 'c') { push @c, [ $title,    "../candidate/#$id" ] }
      elsif ($links{$id} eq 'x') { push @x, [ $title, "../experimental/#$id" ] }
      elsif ($links{$id} eq 'u') { push @u, [ $title,     "../unstaged/#$id" ] }
      else { die "\e[1;31m  bad parent for '$id' in link/\e[m\n"; }
    }
    # return
    TOC_FILTER .
    sprintf qq[<h2 id="%s"><a href="#%s">%s</a></h2>\n%s%s] x 4,
      ('agreed')x2,       'المصطلحات المتفق عليها',     toc_links(@w) // EMPTY_STAGE_LINKS, "\n",
      ('candidate')x2,    'المصطلحات المرشحة للاتفاق',  toc_links(@c) // EMPTY_STAGE_LINKS, "\n",
      ('experimental')x2, 'المصطلحات التجريبية',        toc_links(@x) // EMPTY_STAGE_LINKS, "\n",
      ('unstaged')x2,     'المصطلحات المؤجلة',          toc_links(@u) // EMPTY_STAGE_LINKS, ""
  },
  'all';

