package Parser;
use v5.14; use warnings; use autodie; use utf8;
use open qw[ :encoding(UTF-8) :std ];

use parent 'Exporter';
our @EXPORT_OK = qw[
  filepath_to_html
  html_to_summary
  word_title_of
  short_title_of
];

sub word_title_of(_) {
  return $_[0] =~ s,_, ,gr
  # add here special cases for mixed-case (non-acronym) titles, eg:
  # =~ s/^c\+\+$/C++/gr
}

sub short_title_of(_) {
  local $_ = word_title_of($_[0]);
  return /admin/ ? $_  # admin & sysadmin are abbreviations not acronyms
    : /voip/ ? 'VoIP'
    : uc  # otherwise, uppercase it all
  # add here special cases for mixed-case acronyms or other kinds of abbreviations
}

sub parse_line(_;$) {
  my $title_of = $_[1] // \&word_title_of;
  return $_[0]
    =~ s|<|\x02|grx
    =~ s|>|\x03|grx
    =~ s|\*\*(.*?)\*\*|<strong>$1</strong>|grx
    =~ s|\x02\x02 ([^:>]+) :: ([^:>]+) \x03\x03|<a href="#$2">$1</a>|grx
    =~ s|\x02\x02          :: (.*?)    \x03\x03|qq[<a dir="ltr" href="#$1">].$title_of->($1).qq[</a>]|grxe
    =~ s,\x02\x02 ([^|\x03]*) [|]{2} ([^|\x03]*) \x03\x03,<a rel="noreferrer noopener" href="$2">$1</a>,grx
    =~ s|\x02\x02 (.*?) \x03\x03|<a dir="ltr" rel="noreferrer noopener" href="$1">$1</a>|grx
    =~ s|\{\{(.*?)\}\}|<span dir="ltr">$1</span>|grx
    =~ s|``(.*?)``|<code dir="ltr">$1</code>|grx
    =~ s|~~(.*?)~~|<s>$1</s>|grx
    =~ s|\x02|&lt;|grx
    =~ s|\x03|&gt;|grx
    =~ s|(?<=.)\+\+(?=.)|&nbsp;|gr
    =~ s|$|<br>|r  # no /g or it'd be triggered twice
    =~ s|\h+| |gr  # collapse all horizontal spaces into one normal ASCII space; also replaces \t (for ysmu.tsv)
}

sub transform_see_also(_;$) {
  my $title_of = $_[1] // \&word_title_of;
  return
    sprintf qq[<p class="seealso">انظر أيضا:</p><ul>\n%s\n</ul>],
      join "\n",
        map { s|<br>||; s| |_|g; qq[  <li><a dir="ltr" href="#$_">].$title_of->($_).qq[</a></li>] }
          split "\n", $_[0]
}

sub transform_blockquote(_) {
  return
    sprintf qq[<blockquote>\n%s\n</blockquote>],
      $_[0] =~ s,<br>\n\Z,,r
}

sub transform_list(_) {
  return $_[0]
    =~ s,^<p>--\h+(.*)</p>$,<li>$1</li>,mgr
    # note: '****' are translated to the empty <strong></strong>
    # thus our big list items are started by <p><strong></strong></p>
    =~ s,^<p><strong></strong></p>\n(.*?)(?=\n<p><strong></strong></p>$|\n<li>|\Z),<li>$1</li>,mgrs
}

sub transform_para(_;$) {
  return
    ('<p>'.( $_[0] =~ s|<br>\n<br>\n|</p>\n\n<p>|gr).'</p>')
      =~ s|<p>\h*<br>\n|<p>|gr
      =~ s|<p>\h*</p>||gr
      =~ s|<p>----</p>|<hr>|gr
      =~ s|\A\n+||gr
      =~ s|\n+\Z||gr
      =~ s|\n\n+|\n|gr
      =~ s|<p>::::<br>\n(.*?)</p>|transform_see_also($1, $_[1])|mgrse
      =~ s|<p>"{4}<br>\n(.*?)</p>|transform_blockquote($1)|mgrse
      =~ s|<p>(?:&gt;){4}</p>\n(.*?)\n<p>(?:&lt;){4}</p>|transform_blockquote($1)|mgrse
      =~ s|<p>\[\[([^";]*?)\]\]<br>\n\Q##((\E</p>(.*?)<p>\Q))##\E</p>|qq[<ol style="list-style-type:$1">].transform_list($2).'</ol>'|mgrse
      =~ s|<p>\[\[([^";]*?)\]\]<br>\n\Q++((\E</p>(.*?)<p>\Q))++\E</p>|qq[<ul style="list-style-type:$1">].transform_list($2).'</ul>'|mgrse
      =~ s|<p>\Q##((\E</p>(.*?)<p>\Q))##\E</p>|'<ol>'.transform_list($1).'</ol>'|mgrse
      =~ s|<p>\Q++((\E</p>(.*?)<p>\Q))++\E</p>|'<ul>'.transform_list($1).'</ul>'|mgrse
      =~ s|<p>@@@@</p>|<div style="margin: -1em"></div>|gr
}

sub filepath_to_html(_;$) {
  my $ret = '';
  open my $f, '<', $_[0];
  while (<$f>) {
    $ret .= parse_line $_, $_[1];
  }
  return transform_para $ret, $_[1];
}

sub html_to_summary(_) {
  # get only the first paragraph, and collapse it into a single line
  local $_ = $_[0] =~ s|<p>(.*?)</p>.*|$1|sr;  # /s makes . match any char, including \n
  unless (/[.]<br>\n?|[.]<\/p>|[.]\Z/) {
    die "\e[1;31m  summary has line(s) that don't end in a fullstop.\e[m\n"
      . join '', map { "\e[1;31m    $_\e[m\n" } split "\n";
  }
  return s/<br>\n/  /gr =~ s/ +\Z//gr;
}

1;
