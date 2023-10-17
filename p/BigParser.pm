package BigParser;
use v5.14; use warnings; use autodie; use utf8;
use open qw[ :encoding(UTF-8) :std ];

use parent 'Exporter';
our @EXPORT_OK = qw[
  basic_html_to_big_html
];
# a single function that reads the output of Parser's filepath_to_html on a big file

sub transform_external_resources(_) {
  return
    sprintf qq[<ul class="externallinks">\n%s\n</ul>],
      join "\n",
        map { s|<br>||; sprintf qq[  <li><a target="_blank" href="%s">%s</a></li>], split " ", $_, 2 }
          split "\n", $_[0]
}

sub basic_html_to_big_html(_) {
  return $_[0]
    # a para starting with /==\h*/ (optionally preceded with [[id]]\n is an h2
    =~ s|^<p>==\h*(.*?)</p>|<h2>$1</h2>|mgr  # header-only para
    =~ s|^<p>==\h*(.*?)<br>\n|<h2>$1</h2>\n<p>|mgr
    =~ s|^<p>\[\[(.*?)\]\]<br>\n==\h*(.*?)</p>|<h2 id="$1"><a HREF="#$1">$2</a></h2>|mgr  # header-only para
    =~ s|^<p>\[\[(.*?)\]\]<br>\n==\h*(.*?)<br>\n|<h2 id="$1"><a HREF="#$1">$2</a></h2>\n<p>|mgr
    # list of external resources
    =~ s|^<p>!!!!<br>\n(.*?)</p>|transform_external_resources($1)|mgrse
    # internal (term) links
    =~ s|(<a\b[^>]+href=")#([^"]*">)([^"]*</a>)|$1../link/$2$3|gr
    # lowercase h2's HREF attributes (was made upper to distinguish them form terms)
    =~ s|<a HREF=|<a href=|gr
}

1;
