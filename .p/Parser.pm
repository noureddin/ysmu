package Parser;
use v5.16; use warnings; use utf8;
use open qw[ :encoding(UTF-8) :std ];

use parent 'Exporter';
our @EXPORT_OK = qw[
  filepath_to_html
  parse_entry
];

sub openfile { my ($mode, $fpath) = @_;
  state $modes = {qw[
    r reading  w writing   a appending
    < reading  > writing  >> appending
    r+ read-writing  w+ write-reading   a+ read-appending
    +< read-writing  +> write-reading  +>> read-appending
  ]};
  my @caller = caller; my $trace = "at $caller[1] line $caller[2]";
  my $mode_desc = $modes->{$mode =~ s/b//gr};  # binary (b) is irrelevant and ignored on POSIX systems
  defined $mode_desc or die "bad open mode '$mode' for «$fpath», $trace\n";
  open my $fh, $mode, $fpath or die "Couldn’t open «$fpath» for $mode_desc: $!, $trace\n";
  return $fh;
}

sub parse_line(_;$) {
  return $_[0]
    =~ s|<|\x02|grx
    =~ s|>|\x03|grx
    =~ s|\*\*(.*?)\*\*|<strong>$1</strong>|grx
    =~ s|\x02\x02 ([^:>]+) :: ([^:>]+) \x03\x03|<a href="#$2">$1</a>|grx
    =~ s|\x02\x02          :: (.*?)    \x03\x03|<a dir="ltr" href="#$1"><<title_of:$1>></a>|grx
    =~ s,\x02\x02 ([^|\x03]*) [|]{2} ([^|\x03]*) \x03\x03,<a rel="noreferrer noopener" href="$2">$1</a>,grx
    =~ s|\x02\x02 (.*?) \x03\x03|<a dir="ltr" rel="noreferrer noopener" href="$1">$1</a>|grx
    =~ s|\{\{##(.*?)##\}\}|<span dir="ltr" style="font-variant:small-caps">$1</span>|gr
    =~ s|\{\{(.*?)\}\}|<span dir="ltr">$1</span>|grx
    =~ s|``(.*?)``|<code dir="ltr">$1</code>|grx
    =~ s|~~(.*?)~~|<s>$1</s>|grx
    =~ s|\x02|&lt;|grx
    =~ s|\x03|&gt;|grx
    =~ s|(?<=.)\+\+(?=.)|&nbsp;|gr
    =~ s|$|<br>|r  # no /g or it'd be triggered twice
    =~ s|\h+| |gr  # collapse all horizontal spaces into one normal ASCII space; also replaces \t (for ysmu.tsv)
}

sub transform_see_also(_) {
  return
    sprintf qq[<p class="seealso">انظر أيضا:</p><ul>\n%s\n</ul>],
      join "\n",
        map { s|<br>||; s| |_|g; qq[  <li><a dir="ltr" href="#$_"><<title_of:$_>></a></li>] }
          split "\n", $_[0]
}

sub transform_external_resources(_) {
  return
    sprintf qq[<p class="seealso">اقرأ للاستزادة:</p><ul class="ext">\n%s\n</ul>],
      join "\n",
        map { s|<br>||; sprintf qq[  <li><a rel="noreferrer noopener" href="%s">%s</a></li>], split " ", $_, 2 }
          split "\n", $_[0]
}

sub transform_ar_blockquote(_) {
  return
    sprintf qq[<blockquote>\n%s\n</blockquote>],
      $_[0] =~ s,<br>\n\Z,,r
}

sub transform_en_blockquote(_) {
  return
    sprintf qq[<blockquote lang="en">\n%s\n</blockquote>],
      $_[0] =~ s,<br>\n\Z,,r
}

sub transform_list(_) {
  return $_[0]
    =~ s,^<p>--\h+(.*)</p>$,<li>$1</li>,mgr
    # note: '****' are translated to the empty <strong></strong>
    # thus our big list items are started by <p><strong></strong></p>
    =~ s,^<p><strong></strong></p>\n(.*?)(?=\n<p><strong></strong></p>$|\n<li>|\Z),<li>$1</li>,mgrs
}

sub transform_para(_) {
  return
    ('<p>'.( $_[0] =~ s|<br>\n<br>\n|</p>\n\n<p>|gr).'</p>')
      =~ s|<p>\h*<br>\n|<p>|gr
      =~ s|<p>\h*</p>||gr
      =~ s|<p>----</p>|<hr>|gr
      =~ s|\A\n+||gr
      =~ s|\n+\Z||gr
      =~ s|\n\n+|\n|gr
      =~ s|<p>::::<br>\n(.*?)</p>|transform_see_also($1)|mgrse
      =~ s|<p>"{4}<br>\n(.*?)</p>|transform_ar_blockquote($1)|mgrse
      =~ s|<p>'{4}<br>\n(.*?)</p>|transform_en_blockquote($1)|mgrse
      =~ s|<p>(?:&gt;){4}</p>\n(.*?)\n<p>(?:&lt;){4}</p>|transform_ar_blockquote($1)|mgrse
      =~ s|<p>(?:[{]){4}</p>\n(.*?)\n<p>(?:[}]){4}</p>|transform_en_blockquote($1)|mgrse
      =~ s|<p>\[\[([^";]*?)\]\]<br>\n\Q##((\E</p>(.*?)<p>\Q))##\E</p>|qq[<ol style="list-style-type:$1">].transform_list($2).'</ol>'|mgrse
      =~ s|<p>\[\[([^";]*?)\]\]<br>\n\Q++((\E</p>(.*?)<p>\Q))++\E</p>|qq[<ul style="list-style-type:$1">].transform_list($2).'</ul>'|mgrse
      =~ s|<p>\Q##((\E</p>(.*?)<p>\Q))##\E</p>|'<ol>'.transform_list($1).'</ol>'|mgrse
      =~ s|<p>\Q++((\E</p>(.*?)<p>\Q))++\E</p>|'<ul>'.transform_list($1).'</ul>'|mgrse
      =~ s|<p>@@@@</p>|<div style="margin: -1em"></div>|gr
}

sub basic_html_to_big_html(_) {
  return $_[0]
    ## a para starting with /==\h*/ (optionally preceded with [[id]]\n is an h2
    =~ s|^<p>==\h*(.*?)</p>|<h2>$1</h2>|mgr  # header-only para
    =~ s|^<p>==\h*(.*?)<br>\n|<h2>$1</h2>\n<p>|mgr
    =~ s|^<p>\[\[(.*?)\]\]<br>\n==\h*(.*?)</p>|<h2 id="$1"><a HREF="#$1">$2</a></h2>|mgr  # header-only para
    =~ s|^<p>\[\[(.*?)\]\]<br>\n==\h*(.*?)<br>\n|<h2 id="$1"><a HREF="#$1">$2</a></h2>\n<p>|mgr
    ## list of external resources
    =~ s|^<p>!!!!<br>\n(.*?)</p>|transform_external_resources($1)|mgrse
    ## internal (term) links
    # =~ s|(<a\b[^>]+href=")#([^"]*">)([^"]*</a>)|$1../link/$2$3|gr
    ## lowercase h2's HREF attributes (was made upper to distinguish them form terms)
    =~ s|<a HREF=|<a href=|gr
}

sub filepath_to_html(_) {
  my $ret = '';
  my $f = openfile '<', $_[0];
  while (<$f>) {
    $ret .= parse_line $_;
  }
  return basic_html_to_big_html transform_para $ret;
  $ret =~ s{\A<p>([^\0]*?)</p>}{
    my $sum = $1;
    $sum =~ s|<span dir="ltr">([^<>]*)</span>|\N{LEFT DOUBLE PARENTHESIS}$1\N{RIGHT DOUBLE PARENTHESIS}<br>|g;
    $sum =~ s/<br>\n?/  /g;
    $sum =~ s/  +/  /g;
    $sum =~ s/  \.  /   /g;
    $sum =~ s/ +\z//g;
    # return
    '<p class="main">'.$sum.'</p><hr class="rm">'
  }ge;
  return $ret;
}

sub parse_entry(_) {
  my $ret = filepath_to_html $_[0];
  my $sum;
  $ret =~ s{\A<p>([^\0]*?)</p>}{
    $sum = $1;
    # process summary
    $sum =~ s|<span dir="ltr">([^<>]*)</span>|\N{LEFT DOUBLE PARENTHESIS}$1\N{RIGHT DOUBLE PARENTHESIS}<br>|g;  # definition fields
    $sum =~ s/<br>\n?/  /g;
    $sum =~ s/  +/  /g;
    $sum =~ s/  \.  /   /g;
    $sum =~ s/ +\z//g;
    $sum =~ s/\Q(ج: \E/(ج:\N{NBSP}/g;
    # checks
    unless ($sum =~ /(?:\.|\.\)|\N{RIGHT DOUBLE PARENTHESIS})(?= {2}|\z)/) {
      # actually three line-endings are accepted: a dot, a dot followed by a closing paren, and a closing "field" paren.
      die "\e[1;31m  summary for '$_[0]' has line(s) that don't end in a fullstop.\e[m\n"
        . join '', map { "\e[1;31m    $_\e[m\n" } split / {2,3}/, $sum;
    }
    # summary to html
    my @summary_paras =
      map '<p class="main">'.$_.'</p>',
        map s/ {2}/<br>/gr,
          split " "x3, $sum;
    # return
    join "\n", @summary_paras, '<hr class="rm">'
  }ge;
  return $ret, $sum;
}

1;
