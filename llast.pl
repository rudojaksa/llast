#!/usr/bin/perl
# Copyleft: R.Jaksa 2018, GNU General Public License version 3
use Time::HiRes qw(usleep time stat);
# include "CONFIG.pl"
# include "datetime.pl"
# ---------------------------------------------------------------------------------------------- HELP

$HELP=<<EOF;

NAME
    llast - list last modified files

USAGE
    llast [OPTIONS] FILE|CC(DIR) ...

DESCRIPTION
    List files and symlinks with the ISO 8601 timestamp in the order
    of the last modification (last=first).  It is ls-wrapper preserving
    the coloring of filenames.

OPTIONS
      -h  This help.
      -v  Verbose execution using CD(STDERR).
      -l  Long output (now alias for -sm)
      -8  Print only the first 8 files.
     -nc  No-colors output.
    -md5  Include md5 column.
     -lo  Look into locate database.

SCOPE
    By default, recursive list of files and symlinks is provided.  Symlinks
    are not followed.  Paths searched by CC(-p) or CC(-re) might start with the "./",
    depending on the requested starting CC(FILE)/CC(DIR).  Default start dir is ".".

      -d  Print directories too.
      -f  Files only (no symlinks).

  -n PAT  Filename glob pattern (e.g. *.c), more CC(-n) are or-combined.
  -p PAT  Path glob pattern.  The CC(-n) and CC(-p) are and-combined.
 -re PAT  Path regex pattern.
 -np PAT  Skip directory-path.
-nre PAT  Skip regex directory-paths.
      -i  Case insensitiveness for regex and glob.

     -nr  No recursion (same as CC(-r1))
     -r2  Max recursion 2 (CC(-r0) means not even this directory).
   CC(-r2-3)  Recursion from level 2 to 3.
    CC(-r=2)  Only level 2 paths.

TIME
    Sub-second precision of time is used for the ordering of files,
    unless the CC(-min) switch is used, but only the minutes precision
    is printed by default.

    -min  Use only minutes precision (skip seconds).
    -sec  Print seconds too.
    -sub  Print sub-seconds.
  -epoch  Print CD(UNIX) epoch time.
     -nt  Don't print time.

SIZE
    Output filesize delimiters are: CC(k) for kilo or kibi, CC(M) for mega
    or mebi, CC(G) for giga or gibi.

      -s  Print file-size.
     -sk  Print file-size in kibibytes (KiB).
     -sm  In mebibytes (MiB).
     -sg  In gibibytes (GiB).
    -met  Metric output (1000-based MB, not 1024-based MiB).
     -sK  Metric output (also CC(-sM -sG)).
    -sk0  Integer output, no decimals (also CC(-sm0 -sg0 -sK0 -sM0 -sG0)).

ORDER
    By default, newest items are listed first.  Multiple sorting criteria
    can be used, they are combined according to the rank.

      CC(+t)  Time order (default).
      CC(+s)  Size order.
      CC(+a)  Alphabetical order.

INSTALL
    To install copy the CC(llast) and CC(ll) into your /bin directory.

EOF

# ------------------------------------------------------------------------------------------- VERBOSE
sub error { print STDERR "$CR_$_[0]$CD_\n"; }

# --------------------------------------------------------------------------------------------- ARGVS
foreach(@ARGV) { if($_ eq "-h") { printhelp $HELP; exit 0; }}
foreach(@ARGV) { if($_ eq "-v") { $VERBOSE=1; $_=""; last; }}

# patterns
foreach(@ARGV) { if($_ eq "-i") { $ICASE=1; $_=""; last; }}
our @NAME;
our @PATH;
our @RPATH;
our @NOPATH;
our @NORPATH;
for($i=0;$i<$#ARGV;$i++) { if($ARGV[$i] eq "-n" and $ARGV[$i+1]) {
  push @NAME,$ARGV[$i+1]; $ARGV[$i]=""; $ARGV[$i+1]=""; }}
for($i=0;$i<$#ARGV;$i++) { if($ARGV[$i] eq "-p" and $ARGV[$i+1]) {
  push @PATH,$ARGV[$i+1]; $ARGV[$i]=""; $ARGV[$i+1]=""; }}
for($i=0;$i<$#ARGV;$i++) { if($ARGV[$i] eq "-re" and $ARGV[$i+1]) {
  push @RPATH,$ARGV[$i+1]; $ARGV[$i]=""; $ARGV[$i+1]=""; }}
for($i=0;$i<$#ARGV;$i++) { if($ARGV[$i] eq "-np" and $ARGV[$i+1]) {
  push @NOPATH,$ARGV[$i+1]; $ARGV[$i]=""; $ARGV[$i+1]=""; }}
for($i=0;$i<$#ARGV;$i++) { if($ARGV[$i] eq "-nre" and $ARGV[$i+1]) {
  push @NORPATH,$ARGV[$i+1]; $ARGV[$i]=""; $ARGV[$i+1]=""; }}

foreach(@ARGV) { if($_ eq "-nc")  { $NC=1; $_=""; last; }}
foreach(@ARGV) { if($_ eq "-md5") { $MD5=1; $_=""; last; }}
foreach(@ARGV) { if($_ eq "-d")   { $DIRSTOO=1; $_=""; last; }}
foreach(@ARGV) { if($_ eq "-f")   { $FILESONLY=1; $_=""; last; }}
foreach(@ARGV) { if($_ eq "-lo")  { $LOCATE=1; $_=""; last; }}

# time
foreach(@ARGV) { if($_ eq "-min") { $MINUTES=1; $_=""; last; }}
foreach(@ARGV) { if($_ eq "-sec") { $SECONDS=1; $_=""; last; }}
foreach(@ARGV) { if($_ eq "-sub") { $SECONDS=1; $SUBSEC=1; $_=""; last; }}
foreach(@ARGV) { if($_ eq "-epoch") { $EPOCH=1; $_=""; last; }}
foreach(@ARGV) { if($_ eq "-nt")  { $NOTIME=1; $_=""; last; }}

# size
foreach(@ARGV) { if($_ eq "-s")   { $SIZE=1; $_=""; last; }}
foreach(@ARGV) { if($_ eq "-sk")  { $SIZE=1; $KILO=1; $_=""; last; }}
foreach(@ARGV) { if($_ eq "-sm")  { $SIZE=1; $MEGA=1; $_=""; last; }}
foreach(@ARGV) { if($_ eq "-sg")  { $SIZE=1; $GIGA=1; $_=""; last; }}
foreach(@ARGV) { if($_ eq "-met") { $MET=1; $_=""; last; }}
foreach(@ARGV) { if($_ eq "-sK")  { $SIZE=1; $KILO=1; $MET=1; $_=""; last; }}
foreach(@ARGV) { if($_ eq "-sM")  { $SIZE=1; $MEGA=1; $MET=1; $_=""; last; }}
foreach(@ARGV) { if($_ eq "-sG")  { $SIZE=1; $GIGA=1; $MET=1; $_=""; last; }}
foreach(@ARGV) { if($_ eq "-sk0") { $SIZE=1; $KILO=1; $INT=1; $_=""; last; }}
foreach(@ARGV) { if($_ eq "-sm0") { $SIZE=1; $MEGA=1; $INT=1; $_=""; last; }}
foreach(@ARGV) { if($_ eq "-sg0") { $SIZE=1; $GIGA=1; $INT=1; $_=""; last; }}
foreach(@ARGV) { if($_ eq "-sK0") { $SIZE=1; $KILO=1; $INT=1; $MET=1; $_=""; last; }}
foreach(@ARGV) { if($_ eq "-sM0") { $SIZE=1; $MEGA=1; $INT=1; $MET=1; $_=""; last; }}
foreach(@ARGV) { if($_ eq "-sG0") { $SIZE=1; $GIGA=1; $INT=1; $MET=1; $_=""; last; }}

# recursion
foreach(@ARGV) { if($_ eq "-nr") { $RMAX=1; $_=""; last; }}
foreach(@ARGV) { if($_ =~ /^-r([0-9]+)$/) { $RMAX=$1; $_=""; last; }}
foreach(@ARGV) { if($_ =~ /^-r([0-9]+)-([0-9]+)$/) { $RMIN=$1; $RMAX=$2; $_=""; last; }}
foreach(@ARGV) { if($_ =~ /^-r=([0-9]+)$/) { $RMIN=$1; $RMAX=$1; $_=""; last; }}

# order
foreach(@ARGV) { if($_ eq "+t") { $OTIME=1; $_=""; last; }}
foreach(@ARGV) { if($_ eq "+s") { $OSIZE=1; $_=""; last; }}
foreach(@ARGV) { if($_ eq "+a") { $OALPH=1; $_=""; last; }}
$OTIME=1 if not $OSIZE and not $OALPH;

# -l
foreach(@ARGV) { if($_ eq "-l") { $SIZE=1; $MEGA=1; $_=""; last; }}

# -NUM
foreach(@ARGV) { if($_ =~ /^-([0-9]+)$/) { $ROWS=$1; $_=""; last; }}

# files dirs and wrong arguments
if($LOCATE) { # for locate we accept any string
  foreach(@ARGV) {
    next if $_ eq "";
    push @ARG,$_; }}

else { # for find we accept files and dirs only
  foreach(@ARGV) {
    next if $_ eq "";
    if(-f $_ or -d $_) { push @ARG,$_; next; }
    error "wrong argument: $_"; }}

# --------------------------------------------------------------------------------------- START PATHS
our @START;
our %STARTRAW;

foreach my $s (@ARG) {
  my $raw = $s;
  $s =~ s/\/+$//;
  $s =~ s/^\.\///; # TODO: better beautifying possible! (../this=.)
  pushq \@START,$s;
  $STARTRAW{$s} = $raw; }

push @START,"." if not @START;

if($VERBOSE) {
  foreach(@START) {
    print STDERR "from:";
    print STDERR " $STARTRAW{$_} ->" if $_ ne $STARTRAW{$_};
    print STDERR " $_\n"; }}

# ------------------------------------------------------------------------------------------------ OS

my $os = `uname -s`;
$MAC = 1 if $os =~ /Darwin/;

# --------------------------------------------------------------------------------------------- REGEX

my $re  = qr(^([^ ]+) .* ([0-9]+) ([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9](:[0-9\.]+( [+-][0-9]+)?)?) (.+?)$);
my $rem = qr(^([^ ]+) .* ([0-9]+) ((Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\h+[0-9]+\h+([0-9:]+)) (.+?)$);
$re = $rem if $MAC;

# -------------------------------------------------------------------------------------- FIND COMMAND

# ignore case
my ($sname,$spath,$srpath) = ("-name","-path","-regex");
   ($sname,$spath,$srpath) = ("-iname","-ipath","-iregex") if $ICASE;

# name
my $name;
$name .= " -o $sname '$_'" foreach @NAME;
$name =~ s/^ -o //;
$name = "'(' $name ')'" if $#NAME>0;

# path and regex
my $path;
$path .= " -o $spath '$_'" foreach @PATH;
$path .= " -o $srpath '$_'" foreach @RPATH;
$path =~ s/^ -o //;
$path = "'(' $path ')'" if $#PATH+$#RPATH>0;

# nopath and noregex
my $nopath;
$nopath .= " -o $spath '$_'" foreach @NOPATH;
$nopath .= " -o $srpath '$_'" foreach @NORPATH;
$nopath =~ s/^ -o //;
$nopath = "'(' $nopath ')'" if $#NOPATH+$#NORPATH>-1;
$nopath = " -o $nopath -prune" if $#NOPATH+$#NORPATH>=-1;

# type
my $type = "'(' -type f -o -type l ')'";
$type = "" if $DIRSTOO;
$type = "-type f" if $FILESONLY;
$type = "'(' -type f -o -type d ')'" if $FILESONLY and $DIRSTOO;

# depth
my $depth;
$depth  =  "-mindepth $RMIN" if defined $RMIN;
$depth .= " -maxdepth $RMAX" if defined $RMAX;

my $findcmd = "find __START__ $depth $type $name $path -exec __LS__ '{}' ';' $nopath";
$findcmd =~ s/  +/ /g;

## print STDERR "find: $findcmd\n" if $VERBOSE and not $LOCATE;

# ------------------------------------------------------------------------------------ LOCATE COMMAND

my $locatecmd = "locate";
$locatecmd .= " -i" if $ICASE;
$locatecmd .= " __START__";

# regex
my $regex;
if($#RPATH>=0) {
  $regex .= " -e '$_'" foreach @RPATH;
  $regex = "-i $regex" if $ICASE;
  $regex = " | grep $regex";
  $locatecmd .= $regex; }

# noregex
my $noregex;
if($#NORPATH>=0) {
  $noregex .= " -e '$_'" foreach @NORPATH;
  $noregex = "-i $noregex" if $ICASE;
  $noregex = " | grep -v $noregex";
  $locatecmd .= $noregex; }

$locatecmd =~ s/  +/ /g;
## print STDERR " loc: $locatecmd\n" if $VERBOSE and $LOCATE;

# ---------------------------------------------------------------------------------------- LS COMMAND

my $lscmd = "ls -ld";

if(not $NC) {
  if($MAC) { $lscmd .= " -G"; }
  else { $lscmd .= " --color"; }}

if($MAC) {}
elsif($MINUTES)	{ $lscmd .= " --time-style=long-iso"; }
else		{ $lscmd .= " --time-style=full-iso"; }

## print STDERR "  ls: $lscmd\n" if $VERBOSE;

# ------------------------------------------------------------------------------------------- FNMATCH

# convert fnmatch patterns into regex
sub fnmatch2re {
  my $p = $_[0];
  my $nodbg = $_[1];
  my $pp = $p;
  my %a;
  my $i=0;

  # escapes
  $p =~ s/\\\[/__E_1PAREN__/g;
  $p =~ s/\\\]/__E_2PAREN__/g;
  $p =~ s/\\\*/__E_STAR__/g;
  $p =~ s/\\\?/__E_QMARK__/g;

  # ranges
  while($p =~ s/\[\!(.*?)\]/__RRANGE${i}__/) { $a{$i} = quotemeta $1; $i++; }
  while($p =~ s/\[(.*?)\]/__RANGE${i}__/) { $a{$i} = quotemeta $1; $i++; }

  # star/qmark
  $p =~ s/\*/__STAR__/g;
  $p =~ s/\?/__QMARK__/g;

  # the rest
  $p = quotemeta $p;

  # back
  $p =~ s/__QMARK__/./g;
  $p =~ s/__STAR__/\.\*/g;
  $p =~ s/__RANGE([0-9]+)__/[$a{$1}]/g;
  $p =~ s/__RRANGE([0-9]+)__/[^$a{$1}]/g;
  $p =~ s/__E_QMARK__/\\?/g;
  $p =~ s/__E_STAR__/\\*/g;
  $p =~ s/__E_2PAREN__/\\]/g;
  $p =~ s/__E_1PAREN__/\\[/g;

  print STDERR " fnm: $pp -> $p \n" if $VERBOSE and not $nodbg;
  return $p; }

# whole string fnmatch2re
sub fnmatch2rewh {
  my $p = fnmatch2re $_[0],1;
  $p = "^$p\$";
  print STDERR " fnm: $pp -> $p \n" if $VERBOSE;
  return $p; }

# prepare patterns
our %FNAME;
if($LOCATE) {
  foreach(@NAME) {
    $FNAME{$_} = fnmatch2rewh $_; }}

our %FPATH;
if($LOCATE) {
  foreach(@PATH) {
    $FPATH{$_} = fnmatch2rewh $_; }}

our %FNOPATH;
if($LOCATE) {
  foreach(@NOPATH) {
    $FNOPATH{$_} = fnmatch2rewh $_; }}

# ------------------------------------------------------------------------------------------- LS LOOP

my @ls;
my %startls;

# locate
if($LOCATE) {
  foreach my $start (@START) {
    my $cmd = $locatecmd;
    $cmd =~ s/__START__/$start/;
    print STDERR " cmd: $cmd\n" if $VERBOSE;

    foreach my $lo (split /\n/,`$cmd`) {

      # for locate we have to do -n manually
      if(@NAME) {
	(my $fn = $lo) =~ s/^.*\///;
       	my $fnm = 0;
	foreach(@NAME) { $fnm++ if $fn =~ /$FNAME{$_}/; }
	next if $fnm==0; }

      # for locate we have to do -p manually too
      if(@PATH) {
       	my $fnm = 0;
	foreach(@PATH) { $fnm++ if $lo =~ /$FPATH{$_}/; }
	next if $fnm==0; }

      # nopath
      if(@NOPATH) {
       	my $fnm = 0;
	foreach(@NOPATH) { if($lo =~ /$FNOPATH{$_}/) { $fnm++; last; }}
	next if $fnm>0; }

      # depth
      if(defined $RMAX or defined $RMIN) {
	my $s = $lo;
	my $ds = $s =~ tr/\///;
	next if defined $RMAX and $ds > $RMAX;
	next if defined $RMIN and $ds < $RMIN; }

      # dirs/files
      if($FILESONLY and $DIRSTOO) { # files and dirs = no links
	next if -l $lo; }
      elsif($FILESONLY) { # files
	next if -l $lo or -d $lo; }
      elsif($DIRSTOO) {} # everything
      else { # files and links = no dirs
	next if -d $lo; }

      my $ls = "$lscmd '$lo'"; $ls = "$lscmd \"$lo\"" if $lo =~ /\'/; # just a hack
      $ls = "CLICOLOR_FORCE=1 $ls" if $MAC;
      ## print STDERR "  ls: $ls\n" if $VERBOSE;
      my $s = `$ls 2> /dev/null`;
      $s =~ s/\n$//;
      $s = "---------- 0 nobody nobody 0 0000-00-00 00:00:00.000000000 +0000 $lo" if $s eq "";
      print STDERR "  ls: $s\n" if $VERBOSE;
      push @ls,$s;
      $startls{$s} = $start; }}}

# find
else {
  foreach my $start (@START) {
    my $cmd = $findcmd;
    $cmd =~ s/__LS__/$lscmd/;
    $cmd =~ s/__START__/$start/;

    # ls correction for mac, otherwise colors on mac are off for noninteractive use
    $cmd = "CLICOLOR_FORCE=1 $cmd" if $MAC;
    print STDERR " cmd: $cmd\n" if $VERBOSE;
  
    foreach my $s (split /\n/,`$cmd 2> /dev/null`) { # TODO: signal permission denied somehow to user
      print STDERR "  ls: $s\n" if $VERBOSE;
      push @ls,$s;
      $startls{$s} = $start; }}}

# ----------------------------------------------------------------------------------------- LS PARSER

my @file;  # list of file
my %perm;  # permissions string
my %time;  # time of file
my %size;  # size of file (string)
my %SIZE;  # size of file (in bytes)
my %md5;   # md5 of file
my %color; # color of file
my %start; # start path for find of this file
my %dir;   # entry is directory

foreach my $s (@ls) {

  # regex parse every line
  error "strange ls: $s" if not $s =~ /$re/;
  my ($p,$z,$t,$f,$q) = ($1,$2,$3,$6,quotemeta $&);
  my $start = $startls{$s};
  my $l;

  # extract symlinks
  if($p=~/^l/ and $f=~/^(.+) -> (.+)$/) {
    ($f,$l) = ($1,$2); }

  # extract color (only after this is the filename real)
  my $color;
  if($f =~ /^((\[[0-9;]+m)*)(.*?)((\[[0-9;]+m)*)(\[K)?$/) {
    my ($s1,$s,$s2) = ($1,$3,$4);
    $f = $s;
    $color = $s1; }

  # on MAC use stat to find the precise time
  if($MAC) {
    my $t0 = getmtime $f;
    my $t2 = $1 if $t0 =~ /\.([0-9]+)$/;
    $t = epoch2time($t0);
    $t .= ".$t2" if $t2;
    print STDERR "stat: $t0 ($t)\n" if $VERBOSE; }

  # remove leading ./
  $f =~ s/^\.\/// if $start eq ".";

  # beautify the find-path on mac
  if($MAC) { $f =~ s/\/\/+/\//g; }

  # $f =~ s//----/g;
  ## print STDERR "file: $f\n" if $VERBOSE;
  # if($color) { my $qc = quotemeta $color; print STDERR "colr: $qc\n"; }

  my $dir;
  if($DIRSTOO) { $dir = 1 if -d $f; }

  pushq \@file,$f;
  $perm{$f} = $p;
  $link{$f} = $l;
  $time{$f} = $t;
  $size{$f} = $z;
  $SIZE{$f} = $z;
  $dir{$f} = $dir;
  $start{$f} = $start;
  $color{$f} = $color; }

# --------------------------------------------------------------------------------- OUTPUT ROWS ORDER

# alphabetic order
our %OALPH;
if($OALPH) { my $i=0; $OALPH{$_} = $i++ foreach sort {$b cmp $a} @file; }

# size order
if($OSIZE) { my $i=0; $OSIZE{$_} = $i++ foreach sort {$SIZE{$a} <=> $SIZE{$b}} @file; }

# time order (default)
if($OTIME) { my $i=0; $OTIME{$_} = $i++ foreach sort {$time{$a} cmp $time{$b}} @file; }

# total order
our %TOTAL;
foreach my $f (@file) {
  $TOTAL{$f} = 0;
  $TOTAL{$f} += $OALPH{$f} if $OALPH;
  $TOTAL{$f} += $OSIZE{$f} if $OSIZE;
  $TOTAL{$f} += $OTIME{$f} if $OTIME; }

# apply ordering
my @OUT;
my $i=0;
foreach my $f (sort {$TOTAL{$b} <=> $TOTAL{$a}} @file) {
  last if defined $ROWS and $i>=$ROWS;
  push @OUT,$f;
  $i++; }

# ---------------------------------------------------------------------------------------------- SIZE

# directories size
if($SIZE and $DIRSTOO) {
  foreach my $f (@OUT) {
    next if not $dir{$f};
    my $ducmd = "du -b -s $f";
    $ducmd = "du -s $f" if $MAC;
    print STDERR " du: $ducmd\n" if $VERBOSE;
    my $du = `$ducmd`;
    $du = $1 if $du =~ /^([0-9]+)\h.*$/;
    $du *= 512 if $MAC;
    $size{$f} = $du; }}

# size units
if($SIZE and ($KILO or $MEGA or $GIGA)) {
  foreach my $f (@OUT) {
    my $n = $size{$f};

    my $m;
    if   ($GIGA) { if($MET) { $m = $n/1000000000.0; } else { $m = $n/1073741824.0; }}
    elsif($MEGA) { if($MET) { $m = $n/1000000.0; } else { $m = $n/1048576.0; }}
    elsif($KILO) { if($MET) { $m = $n/1000.0; } else { $m = $n/1024.0; }}

    # rounding
    my $s;
    if($INT) { $s = sprintf "%.0f",$m; }
    else     { $s = sprintf "%.1f",$m; }

    # beautifiyng
    $s = "" if $s eq "0.0";
    $s = "" if $s eq "0";

    # delimiters
    my $d;
    if   ($GIGA) { $d = "G"; }
    elsif($MEGA) { $d = "M"; }
    elsif($KILO) { $d = "k"; }
    if($s eq "") {
      $s = "0"; }
    elsif($INT) {
      $s .= "$d" if $s ne ""; }
    else {
      $s = "$d$1" if $s =~ /^0\.(.)$/;
      $s =~ s/\./$d/;
      $s =~ s/${d}0$/$d /; }

    $size{$f} = $s; }}

# length of the longest size-string
my $sizelen = -1;
if($SIZE) {
  foreach my $f (@OUT) {
    my $l = length $size{$f};
    $sizelen = $l if $sizelen == -1;
    $sizelen = $l if $sizelen < $l; }}

# ----------------------------------------------------------------------------------------------- MD5

sub getmd5 {
  my $f = $_[0];
  my $cmd = "md5sum '$f' 2> /tmp/llast.md5sum";
  $cmd = "md5 -q '$f' 2> /tmp/llast.md5sum" if $MAC;
  print STDERR " md5: $cmd\n" if $VERBOSE;
  my $md5 = `$cmd`;
  if($md5 =~ /^([0-9a-f]+)(\h|$)/) {
    $md5{$f} = $1; }
  else {
    my $err = `cat /tmp/llast.md5sum`;
    $err =~ s/^md5sum:\h*//;
    $err =~ s/\n//g;
    error "no md5sum for: $f $CK_($err)"; }}

# ----------------------------------------------------------------------- PRINT SINGLE LINE OF OUTPUT

sub line {
  my $f = $_[0];

  my $color = $color{$f};
  my $file = $f;
  $file ="$color$f$CD_" if not $NC and $color;

  # space-ended paths
  if(not $NC and ($f =~ /^\h/ or $f =~ /\h$/)) {
    $file = "${CK_}[$CD_$file${CK_}]$CD_"; }

  # links pointing to...
  if(defined $link{$f}) {
    $file .= " -> $link{$f}"; }

  my $time;
  if(not $NOTIME) {
    $time = $time{$f};
    if($EPOCH) {
      $time =~ s/ [+-][0-9]+$//;						# remove timezone
      $time =~ s/\.[0-9]+$//;							# remove sub-seconds
      $time = (time2epoch($time))[0]; }
    else {
      $time =~ s/ [+-][0-9]+$//;						# don't display timezone
      $time =~ s/\.[0-9]+$// if not $SUBSEC;					# don't display sub-seconds
      $time =~ s/ ([0-9][0-9]:[0-9][0-9]):[0-9\.]+$/ $1/ if not $SECONDS; }	# don't display seconds
    $time = "$CK_$time$CD_" if not $NC;
    $time .= " "; }

  my $size;
  if($SIZE) {
    $size{$f} .= " " if $size{$f} eq "0" and not $INT and $sizelen>1 and ($KILO or $MEGA or $GIGA);
    $size = sprintf "%${sizelen}s ",$size{$f};
    $size =~ s/^(\h*)(0\h*)$/$1${CK_}$2$CD_/ if not $NC;
    $size =~ s/([kMG])(.*)/${CK_}$1$2$CD_/ if not $NC; }

  my $md5;
  if($MD5) {
    getmd5 $f if not $dir{$f} and $size{$f}>0 and not $link{$f};
    $md5 = "$md5{$f} ";
    if($md5 eq " ") {
      $md5 = "00000000000000000000000000000000";
      $md5 = "$CK_$md5$CD_" if not $NC;
      $md5 .= " "; }}

  print "$time$size$md5$file\n"; }

# -------------------------------------------------------------------------------------- PRINT OUTPUT

foreach my $f (@OUT) {
  line $f; }

# ---------------------------------------------------------------------------------------------------
