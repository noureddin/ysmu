package GenAtom;
use v5.16; use warnings; use utf8;
use open qw[ :encoding(UTF-8) :std ];

use parent 'Exporter';
our @EXPORT_OK = qw[
  gen_atom
];

use Time::Piece;  # for converting unix time to UTC ISO dates (git uses local TZ)
use List::Util qw[ max maxstr ];  # for the Atom feed

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

# returns the latest modification time of a term, whether a change
#   of the summary, the stage, the description, or a piece of metadata.
# ISO date in UTC; b/c git returns the date in the TZ of the commiter.
sub updated_from_path {
  # must check if not in git yet.
  my $path = $_[0] =~ s|'|'\\''|gr;
  my $unix = `git ls-files '$path'` eq ''
    ? undef  # not in git => updated = now
    : `git log --follow --pretty=format:%ad --date=unix -1 -- $path`;
  my $time = Time::Piece->new($unix);
  my $date = ($time - $time->tzoffset)->datetime . 'Z';
}

# returns the earliest creation time of a term file in all stages.
# ISO date in UTC; b/c git returns the date in the TZ of the commiter
sub published_from_basename {
  # if not in git yet, git doesn't error, and Time::Piece gives us "now" (b/c $unix is undef).
  my $base = $_[0] =~ s|'|'\\''|gr;
  my $unix = (`git log --follow --pretty=format:%ad --date=unix -- ?/'$base'`)[-1];
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

# https://www.ietf.org/archive/id/draft-snell-atompub-bidi-05.html
# dir="rtl" is not widely supported, even https://validator.w3.org/feed/ warns about it,
# so Unicode RTL embedding is still needed.

# ASSUMPTION: if the arg contains RTL or LTR EMBED, it must be balanced with POP DIR.
sub RTL(_) { "\N{RIGHT-TO-LEFT EMBEDDING}" . $_[0] . "\N{POP DIRECTIONAL FORMATTING}" }

use constant ATOM_HEAD => <<'END_OF_TEXT' =~ s/>\s+</></gr;
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom" xml:lang="ar" dir="rtl">
  <title>معجم يسمو للمصطلحات التقنية الحديثة</title>
  <link rel="alternate" type="text/html" href="https://www.noureddin.dev/ysmu/" />
  <link rel="self" type="application/atom+xml" href="https://www.noureddin.dev/ysmu/feed.atom" />
  <icon>https://www.noureddin.dev/ysmu/etc/favicon-72x72.png</icon>
  <updated>{{UPDATED}}</updated>
  <id>tag:ysmu.noureddin.dev,2023:/feed.atom.xml</id>
  <author>
    <name>نور الدين | Noureddin</name>
    <uri>https://www.noureddin.dev/</uri>
  </author>
END_OF_TEXT


sub gen_atom {
  my %terms = @_;

  # include only Accepted or Candidate terms, but not Experimental or Unstaged terms
  %terms =
    map { $_ => $terms{$_} }
    grep { $terms{$_}{cat} =~ /^[wc]$/ }
      keys %terms;


  my %upd;
  my %pub;
  for my $t (keys %terms) {
    $upd{$t} = updated_from_path $terms{$t}{file};
    $pub{$t} = published_from_basename $terms{$t}{file} =~ s,.*/,,r;
  }

  my $updated = maxstr values %upd;

  my $m = openfile '>', 'feed.atom.xml';
  print { $m } ATOM_HEAD =~ s|\Q{{UPDATED}}\E|$updated|gr;

  # ASCIIbetical sort, to keep the diffs low when changing summary translations or moving terms between stages
  # TODO: case-insensitivity? (eg., for terms with proper names)
  for my $id (sort keys %terms) {
    my $tag = $tags{ $terms{$id}{cat} };
    my $sum = $terms{$id}{summary};
    my $upd = $upd{$id};
    my $pub = $pub{$id};
    print { $m }
      '<entry>',
      '<title>', $terms{$id}{title}, '</title>',
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
}

1;
