#!/usr/bin/env perl
# vim: set foldmethod=marker foldmarker={{{,}}} :
use v5.14; use warnings; use autodie; use utf8;
use open qw[ :encoding(UTF-8) :std ];

# static definitions {{{1

sub slurp(_) { local $/; open my $f, '<', $_[0]; return scalar <$f> }

use Time::Piece;  # for converting unix time to UTC ISO dates (git uses local TZ)
use List::Util qw[ max maxstr ];  # for the Atom feed

use FindBin;
# allow loading our libraries from the script's directory
use lib $FindBin::RealBin;
# change to the repo's root, regardless where we're called from.
chdir "$FindBin::RealBin/../";

# for hashing static files to cache-bust them on change
use Digest::file qw[ digest_file_base64 ];
sub hash(_) { digest_file_base64(shift, 'SHA-1') =~ tr[+/][-_]r }

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
  <link rel="stylesheet" type="text/css" href="{{root}}etc/style.min.css?h={{stylehash}}">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta property="og:locale" content="ar_AR">
  <meta property="og:type" content="website">
  <meta property="og:title" content="{{title}}">
  <link rel="canonical" href="{{url}}">
  <meta property="og:url" content="{{url}}">
  <link rel="icon" type="image/png" sizes="72x72" href="{{root}}etc/favicon-72x72.png">
  <link rel="icon" type="image/png" sizes="16x16" href="{{root}}etc/favicon-16x16.png">
  <link rel="icon" type="image/svg+xml" sizes="any" href="{{root}}etc/favicon.svg">
  <!-- icon is U+1F304 from Twemoji (https://twemoji.twitter.com/) CC-BY 4.0 -->
</head>
<body>
<header>
<p class="title">
{{header_title}}
</p>
<nav>
<a href="{{root}}">المصطلحات المتفق عليها</a> |
<a href="{{root}}candidate/">المصطلحات المرشحة للاتفاق</a> |
<a rel=index href="{{root}}link/">روابط جميع المصطلحات</a> |
<a rel=help href="{{root}}notes/">موارد</a>
</nav>
</header>
END_OF_TEXT


sub make_header { my ($additional_title, $path, $base) = @_;
  $path //= '';
  my $root = $base ? $base :
             $additional_title ? '../' : '';
  my $desc = $additional_title ? ' — '.$additional_title : ' للمصطلحات التقنية الحديثة';
  my $url  = "https://www.noureddin.dev/ysmu/$path/" =~ s,/+$,/,r;
  my $page = $path ? "$root$path/" : '';
  my $title = "معجم يسمو$desc";
  my $header_title = "معجم يسمو\n{{logo}}\n$desc" =~ s/ — //r
    =~ s|\Q{{logo}}\E|<span class="logo"><span>\N{SUNRISE OVER MOUNTAINS}</span></span>|r;
    # this hack (with the associated css) is to use the img on css-enabled browsers,
    # but to use the unicode character in reader mode and browsers w/o css.

  return HEADER
    =~ s,\Q{{title}}\E,$title,gr
    =~ s,\Q{{header_title}}\E,$header_title,gr
    =~ s,\Q{{url}}\E,$url,gr
    =~ s,\Q{{root}}\E,$root,gr
    =~ s,\Q{{stylehash}}\E,hash('etc/style.min.css'),gre
    =~ s,\Qhref="$page"\E,aria-current="page",gr
    =~ s,\n\Z,,r  # to use say with almost everything
    # ensure proper text direction for the page's title (TODO: only for <title> and not meta og:title?)
    =~ s,(?<=<title>),\N{RIGHT-TO-LEFT EMBEDDING},r
    =~ s,(?=</title>),\N{POP DIRECTIONAL FORMATTING},r
}

my $feedicon = slurp 'etc/feed-icon.svg';
# based on https://en.wikipedia.org/wiki/File:Feed-icon.svg
# flipped & made monochrome with Inkscape,
# then compressed with vecta.io/nano
# then modified manually a bit.

use constant FOOTER => <<'END_OF_TEXT' =~ s,\n\Z,,r;  # to use say with almost everything
<footer>
  <!--before-contact-->
  <p>يمكنك التواصل معنا عبر
    صفحة <a rel="noreferrer noopener" href="https://github.com/noureddin/ysmu/issues/">مسائل GitHub</a><br>
    أو غرفة الترجمة في مجتمع أسس على شبكة ماتركس: <a rel="noreferrer noopener" dir="ltr" href="https://matrix.to/#/#localization:aosus.org">#localization:aosus.org</a>
  </p>
  <!--after-contact-->
  <p class="blurred"><a href="{{root}}feed.atom.xml">تغذية Atom {{feedicon}}</a></p>
  <!--before-license-->
  <p class="license blurred">الرخصة: <a rel="noreferrer noopener license" href="https://creativecommons.org/choose/zero/">Creative Commons Zero (CC0)</a> (مكافئة للملكية العامة)</p>
  <p class="license blurred">الشارة من <a rel="noreferrer noopener" href="https://twemoji.twitter.com/">Twemoji</a> (بترخيص CC-BY 4.0)، مع حرف العين <a href="https://www.amirifont.org/">بالخط الأميري</a></p>
</footer>
</body>
</html>
END_OF_TEXT

use constant FILTERING_SCRIPT => <<'END_OF_TEXT';
<script>
  function normalize_text (t) {
    return (t
      .toLowerCase()
      .replace(/[\u0640\u064B-\u065F]+/g, '')
      .replace(/[-_\s,،.;؛?؟!()]+/g, ' ')
      .replace(/^ /g, '').replace(/ $/g, ' ')
      )
  }
  function filter_terms (q) {
    var tocens = document.querySelectorAll('.toc > a')
    /***before*loop***/
    for (var i = 0; i < tocens.length; ++i) {
      var a = tocens[i]
      var nq = normalize_text(q)
      a.className
       = normalize_text(a.textContent).indexOf(nq) === -1
      && normalize_text(a.title).indexOf(nq) === -1
          ? 'hidden'
          : ''
      /***end*of*loop***/
    }
    /***after*loop***/
  }
  onload = function () {
    document.getElementById('toc_filter').oninput = function () { filter_terms(this.value) }
  }
</script>
END_OF_TEXT

use constant SINGLE_FILTERING_SCRIPT => FILTERING_SCRIPT
  =~ s{\Q/***before*loop***/\E}{var nonempty = false}r
  =~ s{\Q/***end*of*loop***/\E}{if (a.className === '') { nonempty = true }}r
  =~ s{\Q/***after*loop***/\E}
    {document.querySelector('.emptytoc').style.display = nonempty ? 'none' : 'block'}r
  ;

use constant MULTIPLE_FILTERING_SCRIPT => FILTERING_SCRIPT
  =~ s{^ *\Q/***before*loop***/\E\n}{}mr
  =~ s{^ *\Q/***end*of*loop***/\E\n}{}mr
  =~ s{^( *)\Q/***after*loop***/\E\n}
{$1var tocs = document.querySelectorAll('.toc')
$1for (var i = 0; i < tocs.length; ++i) {
$1  tocs[i].querySelector('.emptytoc').style.display =
$1    tocs[i].querySelector('a:not(.hidden)') == null
$1      ? 'block' : 'none'
$1}
}mr
  ;

sub all_link    { '<a rel=index href="'.($_[0] // '').'link/">قائمة روابط جميع المصطلحات</a>' }
sub notes_link  { '<a rel=help href="'.($_[0] // '').'notes/">موارد وإرشادات</a>' }
sub rc_link     { '<a href="'.($_[0] // '').'candidate/">المصطلحات المرشحة للاتفاق</a>' }
sub exper_link  { '<a href="'.($_[0] // '').'experimental/">المصطلحات التجريبية</a>' }
sub tsv_link    { '<a rel=alternate type=text/tab-separated-values href="https://github.com/noureddin/ysmu/raw/main/ysmu.tsv">ysmu.tsv</a>' }
sub stable_link { '<a href="..">المصطلحات المتفق عليها</a>' }

sub make_footer { my ($s) = @_;
  return
  ( $s eq 'stable' ? FOOTER
      =~ s|<!--before-contact-->|<p>يمكنك أيضا رؤية @{[ rc_link ]}</p>|r
      =~ s|<!--after-contact-->|<p class="blurred">الترجمة المختصرة بصيغة TSV للتطبيقات والمعاجم: @{[ tsv_link ]}</p>|r
      =~ s,\Q{{root}}\E,,r
      =~ s,(?=</body>),@{[ SINGLE_FILTERING_SCRIPT ]},r

  : $s eq 'empty stable' ? FOOTER
      =~ s|<!--before-contact-->|<p>يمكنك رؤية @{[ rc_link ]}</p>|r
      =~ s,\Q{{root}}\E,,r

  : $s eq 'candidate' ? FOOTER
      =~ s|<!--before-contact-->|<p>يمكنك أيضا رؤية @{[ exper_link '../' ]}</p>|r
      =~ s,(?=</body>),@{[ SINGLE_FILTERING_SCRIPT ]},r

  : $s eq 'empty candidate' ? FOOTER
      =~ s|<!--before-contact-->|<p>يمكنك رؤية @{[ exper_link '../' ]}</p>|r

  : $s eq 'experimental' ? FOOTER
      =~ s|<!--after-contact-->|<p class="blurred">انظر أيضا: @{[ notes_link '../' ]}</p>|r
      =~ s,(?=</body>),@{[ SINGLE_FILTERING_SCRIPT ]},r

  : $s eq 'empty experimental' ? FOOTER
      =~ s|<!--before-license-->|<p class="blurred">انظر أيضا: @{[ notes_link '../' ]}</p>|r

  : $s eq 'unstaged' ? FOOTER
      =~ s,(?=</body>),@{[ SINGLE_FILTERING_SCRIPT ]},r

  : $s eq 'empty unstaged' ? FOOTER

  : $s eq 'all' ? FOOTER
      =~ s,(?=</body>),@{[ MULTIPLE_FILTERING_SCRIPT ]},r

  : $s eq 'link' ? FOOTER
      =~ s,\Q{{root}}\E,../../,r

  : $s eq 'notes' ? FOOTER
      # =~ s|<!--before-contact-->|<p>يمكنك رؤية @{[ stable_link ]} أو @{[ exper_link '../' ]}</p>|r
      =~ s|<!--before-contact-->|<p>يمكنك رؤية @{[ all_link '../' ]}</p>|r

  : die "\e[1;31m  make_footer received wrong argument: '$s'\e[m\n"
  )
    =~ s,\Q{{root}}\E,../,r
    =~ s/\Q{{feedicon}}\E/$feedicon/r
    =~ s| *<!--.*--> *\n||gr
}

# dynamic definitions {{{1

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

# for each term, we generate a link in link/TERM/ that redirects to it in
# the agreed-upon, candidate, experimental, or unstaged page,
# in that order, so it's easier to link to term before they're stabilized.
my %links;

# each entry has a summary. we keep it in the toc links for search.
my %summs;

sub toc_links {  # takes array of [$id, "#$id"]; returns a string '<section class="toc">...</section>' or undef
  if (@_) {
    return qq[<section class="toc">\n] . (
      join '',
        map {
          my $sum = "\N{RIGHT-TO-LEFT EMBEDDING}$summs{$_->[2]}\N{POP DIRECTIONAL FORMATTING}";
          qq[  <a href="$_->[1]" title="$sum">$_->[0]</a>\n]
        }
        sort { $a->[1] cmp $b->[1] }
        map { [ human_title_of($_->[0]), $_->[1], $_->[0] ] }
          @_
    ) . qq[  <div class="emptytoc blurred" style="display:none">لا توجد مصطلحات متطابقة</div>\n</section>];
  }
  return;  # undef if empty
}

sub _make_entry { my ($file) = @_;
  my $id = $file =~ s,^.*/,,r;
  my $h_id = qq[ id="$id"];
  my $a_id = exists $long{$id} ? qq[ id="$long{$id}"] : '';
  my $title = human_title_of($id);
  my $html = filepath_to_html $file, \&human_title_of;
  $links{$id} = $file =~ s,/.*,,r unless exists $links{$id};
  $summs{$id} = html_to_summary $html;
  # NOTE: files MUST use the short name
  return (
    toclinkpair => [ $id, '#'.$id ],
    entry => qq[<article><h2$h_id><a$a_id dir="ltr" href="#$id">$title</a></h2>\n$html\n</article>],
    summary => (join "\t", $title, $summs{$id}),
  );
}

use constant TOC_FILTER => sprintf "<input %s>\n", join ' ',
  'id="toc_filter"', 'type="text"', 'dir="ltr"',
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

# page & TSV generation {{{1

# we generate these files:
#   index.html, which contains the agreed-upon entries (in w/*).
#   ysmu.tsv, which summarizes the agreed-upon entries (in w/*).
#   candidate/index.html, which contains the "release candidate" entries (in c/*).
#   experimental/index.html, which contains the experimental entries (in x/*).
#   unstaged/index.html, which contains the unstaged entries (in u/*).
#   feed.atom.xml, which contains an Atom feed of all the terms with their summary definitions.
#   notes/index.html from notes/src, which is general prose.
#   link/index.html, which is an index of all terms in the four stages.
#   link/TERM/index.html, that redirects to '#TERM' in the right page.

# we start with the stable entries

open my $index, '>', 'index.html';
open my $summary, '>', 'ysmu.tsv';

say { $index } make_header;

if (make_entries($index, $summary, <w/*>)) {  # if non-empty
  say { $index } make_footer 'stable';
}
else {  # if empty
  say { $index } '<article class="emptypage">لا توجد مصطلحات متفق عليها بعد</article>';
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
  <aside class="alert">
    <strong>تنبيه:</strong>
    $alert؛
    انظر @{[ stable_link ]}
  </aside>
  END_OF_TEXT
  #
  if (make_entries($fh, undef, <$words_dir/*>)) {  # if non-empty
    say { $fh } make_footer $name;
  }
  else {  # if empty
    say { $fh } qq[<article class="emptypage">$emptymsg</article>];
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
    qq[<center class="redirect">ستوجه الآن إلى <a dir="ltr" href="$url">$title</a> آليا<br>(اضغط على الرابط أعلاه إن لم توجه)</center>];
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
      # %links sorting is not enough, b/c if an acronym exists it's used for sorting (eg, 2FA).
      if    ($links{$id} eq 'w') { push @w, [ $id,              "../#$id" ] }
      elsif ($links{$id} eq 'c') { push @c, [ $id,    "../candidate/#$id" ] }
      elsif ($links{$id} eq 'x') { push @x, [ $id, "../experimental/#$id" ] }
      elsif ($links{$id} eq 'u') { push @u, [ $id,     "../unstaged/#$id" ] }
      else { die "\e[1;31m  bad parent for '$id' in link/\e[m\n"; }
    }
    # return
    TOC_FILTER .
    sprintf qq[<section><h2><a class="other" href="../%s">%s</a></h2>\n%s\n</section>%s] x 4,
      '',              'المصطلحات المتفق عليها',     toc_links(@w) // EMPTY_STAGE_LINKS, "\n",
      'candidate/',    'المصطلحات المرشحة للاتفاق',  toc_links(@c) // EMPTY_STAGE_LINKS, "\n",
      'experimental/', 'المصطلحات التجريبية',        toc_links(@x) // EMPTY_STAGE_LINKS, "\n",
      'unstaged/',     'المصطلحات المؤجلة',          toc_links(@u) // EMPTY_STAGE_LINKS, ""
  },
  'all';

# the Atom feed {{{1

# returns the latest modification time of the summary line of a concrete path.
# ISO date in UTC; b/c git returns the date in the TZ of the commiter
sub updated_from_path {
  my $path = $_[0] =~ s|'|'\\''|gr;
  my $unix = `git blame -L,1 --date=format:'<<<%s>>>' '$path'` =~ s/.*<<<([0-9]+)>>>.*\n/$1/r;
  my $time = Time::Piece->new($unix);
  my $date = ($time - $time->tzoffset)->datetime . 'Z';
}

# returns the earliest creation time of a term file in all stages.
# ISO date in UTC; b/c git returns the date in the TZ of the commiter
sub published_from_basename {
  my $base = $_[0] =~ s|'|'\\''|gr;
  my $unix = (split "\n", `git log --diff-filter=A --pretty=format:%cd --date=unix --reverse -- '?/$base'`)[0];
  my $time = Time::Piece->new($unix);
  my $date = ($time - $time->tzoffset)->datetime . 'Z';
}

my %tags = map { $_->[0] => sprintf '<link rel="alternate" href="%s/#"/><category scheme="https://www.noureddin.dev/ysmu/%s" term="%s" label="%s"/>', @{$_->[1]} } (
  [w => [('')x2, 'stable',   'المصطلحات المتفق عليها']],
  [c => [('candidate')x3,    'المصطلحات المرشحة للاتفاق']],
  [x => [('experimental')x3, 'المصطلحات التجريبية']],
  [u => [('unstaged')x3,     'المصطلحات المؤجلة']],
);

# this cannot give undef for a link; otherwise it would have died in the links index

my %upd = map { $_ => updated_from_path $links{$_} .'/'. $_ } keys %links;

my $updated = maxstr values %upd;

open my $m, '>', 'feed.atom.xml';
print { $m } <<"END_OF_TEXT" =~ s/>\s+</></gr;
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom" xml:lang="ar" dir="rtl">
  <title>معجم يسمو للمصطلحات التقنية الحديثة</title>
  <link rel="alternate" type="text/html" href="https://www.noureddin.dev/ysmu/" />
  <link rel="self" type="application/atom+xml" href="https://www.noureddin.dev/ysmu/feed.atom" />
  <icon>https://www.noureddin.dev/ysmu/etc/favicon-72x72.png</icon>
  <updated>$updated</updated>
  <id>tag:ysmu.noureddin.dev,2023:/feed.atom.xml</id>
  <author>
    <name>نور الدين | Noureddin</name>
    <uri>https://www.noureddin.dev/</uri>
  </author>
END_OF_TEXT

# https://www.ietf.org/archive/id/draft-snell-atompub-bidi-05.html
# dir="rtl" is not widely supported, even https://validator.w3.org/feed/ warns about it,
# so Unicode RTL embedding is still needed.

use charnames ":full", ":alias" => {
  LTR => "LEFT-TO-RIGHT EMBEDDING",
  RTL => "RIGHT-TO-LEFT EMBEDDING",
  POP => "POP DIRECTIONAL FORMATTING",
};

# ASSUMPTION: if the arg contains RTL or LTR EMBED, it must be balanced with POP DIR.
sub RTL(_) { "\N{RTL}" . $_[0] . "\N{POP}" }

# reverse chronological order of last update of the summary.
# if more than one has the same update time (quite common),
# sort by reverse ASCIIbetical order, so that it's in a regular ASCIIbetical order.
for my $id (reverse sort { $upd{$a} cmp $upd{$b} || $b cmp $a } keys %upd) {
  my $tag = $tags{ $links{$id} };
  my $sum = $summs{$id};
  my $upd = $upd{$id};
  my $pub = published_from_basename $id;
  print { $m }
    '<entry>',
    '<title>', $id, '</title>',
    $tag =~ s/#/#$id/gr,
    '<updated>', $upd, '</updated>',
    '<published>', $pub, '</published>',
    '<id>tag:ysmu.noureddin.dev,2023:/', $id, '</id>',
    '<summary>', RTL($sum), '</summary>',
    # TODO: content
    '</entry>', "\n";
}

print { $m } '</feed>';
close $m;

