# TODO: %2d vers %d output, also in all debugs

use Time::Local 'timelocal_nocheck';
use Time::Local 'timegm_nocheck';

# ---------------------------------------------------------------------------

$DEBUG = 0 if not defined $DEBUG;

sub debug {
  my $s=$_[1]; $s=~s/\n$//;
  printf STDERR "%7s: %s\n",$_[0],$s if $DEBUG; }

# ------------------------------------------------------------------- DATEADD

# "2014-02-02" = dateadd_(2014,02,05,-3)
sub dateadd_ {
  my $y = $_[0];
  my $m = $_[1];
  my $d = $_[2];
  my $diff = $_[3];
  debug "parsed","$y-$m-$d ($diff)";

  my $epoch = timegm_nocheck(0,0,0,$d,$m-1,$y) + $diff*24*60*60;
  my ($ny,$nm,$nd) = (gmtime($epoch))[5,4,3];
  my $date = sprintf "%d-%02d-%02d",$ny+1900,$nm+1,$nd;
  debug "result",$date;

  return $date; }

# "2014-02-02 2014-12-02" = dateadd("2014-02-05 2014-12-05",-3)
my $RE = qr(([0-9]{4})-([01]?[0-9])-([0-3]?[0-9]));
sub dateadd {
  my $date = $_[0];
  my $diff = $_[1];
  my $n=0; # index of date string
  my @ds;  # array of date replacement strings

  # parser
  while($date =~ /(?:\h|^)($RE)(?=\h|$)/) {
    my $q   = quotemeta $1;
    $ds[$n] = dateadd_($2,$3,$4,$diff);
    $date =~ s/$q/__DATE${n}__/; $n++; }

  # compiler
  for(my $i=0; $i<$n; $i++) {
    $date =~ s/__DATE${i}__/$ds[$i]/; }

  debug "output",$date;
  return $date; }

# ------------------------------------------------------------------- TIMEADD
# regex for "2014-1-23 13:1:22Z"
# ($year,$month,$day,$hour,$minute,$second,$isutc) = ($2,$3,$4,$6,$7,$9,$10);
my $REtime = qr(([0-9]{4})-([01]?[0-9])-([0-3]?[0-9])(\h+([0-9]+):([0-9]+)(:([0-9]+))?(Z)?)?);
#   my $RE = qr(([0-9]{4})-([01]?[0-9])-([0-3]?[0-9])\h+([0-2]?[0-9]):([0-5]?[0-9])(:([0-6]?[0-9]))?Z?);

# 3600 = tdiffparse(1), 61 = tdiffparse(":1:1")
sub tdiffparse {
  my $s = $_[0];
  my $H = 0;
  my $M = 0;
  my $S = 0;
  my $sig = 1;
  if($s =~ /^(-)?([0-9]*):([0-9]*):([0-9]*)$/) {
    $sig = -1 if $1 eq "-";
    $H = $2 if $2;
    $M = $3 if $3;
    $S = $4 if $4; }
  elsif($s =~ /^(-)?([0-9]*):([0-9]*)$/) {
    $sig = -1 if $1 eq "-";
    $H = $2 if $2;
    $M = $3 if $3; }
  elsif($s =~ /^(-)?([0-9]+)$/) {
    $sig = -1 if $1 eq "-";
    $H = $2 if $2; }
  return($sig * ($H*3600 + $M*60 + $S)); }

# "2014-02-02" = dateadd_(2014,02,05,-3)
sub timeadd_ {
  my $y = $_[0];
  my $m = $_[1];
  my $d = $_[2];
  my $H = $_[3]; $H=0 if not defined $H;
  my $M = $_[4]; $M=0 if not defined $M;
  my $S = $_[5]; $S=0 if not defined $S;
  my $diff = $_[6];
  my $isutc = $_[7];

  my $input = sprintf "%d-%02d-%02d %02d:%02d:%02d",$y,$m,$d,$H,$M,$S;
  $input .= "Z" if $isutc;

  my $epoch;
  my ($S2,$M2,$H2,$d2,$m2,$y2);
  if($isutc) {
    $epoch = timegm_nocheck($S,$M,$H,$d,$m-1,$y) + $diff;
    ($S2,$M2,$H2,$d2,$m2,$y2) = (gmtime($epoch))[0,1,2,3,4,5]; }
  else {
    $epoch = timelocal_nocheck($S,$M,$H,$d,$m-1,$y) + $diff;
    ($S2,$M2,$H2,$d2,$m2,$y2) = (localtime($epoch))[0,1,2,3,4,5]; }
  $y2 += 1900;
  $m2 += 1;

  my $output = sprintf "%d-%02d-%02d %02d:%02d:%02d",$y2,$m2,$d2,$H2,$M2,$S2;
  $output .= "Z" if $isutc;

  debug "convert","$input -> $output";
  return $output; }

# "2014-02-02 2014-12-02" = dateadd("2014-02-05 2014-12-05",-3)
sub timeadd {
  my $date = $_[0];
  my $diff = $_[1];
  debug "dates",$date;

  # diff
  my $sec = tdiffparse($diff);
  debug "diff","$diff = $sec";

  my $n=0; # index of date string
  my @ds;  # array of date replacement strings

  # parser
  while($date =~ /(?:\h|^)($REtime)(?=\h|$)/) {
    my $q   = quotemeta $1;
    $ds[$n] = timeadd_($2,$3,$4,$6,$7,$9,$sec,$10);
    $date =~ s/$q/__DATE${n}__/; $n++; }

  # compiler
  for(my $i=0; $i<$n; $i++) {
    $date =~ s/__DATE${i}__/$ds[$i]/; }

  debug "output",$date;
  return $date; }

# ------------------------------------------------------------------- UTC2LOC

sub utc2loc6 {
  my $y = $_[0];
  my $m = $_[1];
  my $d = $_[2];
  my $H = $_[3];
  my $M = $_[4];
  my $S = $_[5];
  debug "parsed","$y-$m-$d $H:$M:${S}Z";

  # corrections
  my $c=0; # flag: whether corrected
  while($H>=24) { $H-=24; $d++; $c=1; } 
  debug "corrected","$y-$m-$d $H:$M:${S}Z" if $c;

  # localtime
  my $epoch = timegm_nocheck($S,$M,$H,$d,$m-1,$y);
  my ($ly,$lm,$ld,$lH,$lM,$lS,$isdst) = (localtime($epoch))[5,4,3,2,1,0,8];
  $ly += 1900;
  $lm += 1;

  # formatting
  my $s = sprintf "%04d-%02d-%02d %02d:%02d:%02d",$ly,$lm,$ld,$lH,$lM,$lS;
  my $dst; $dst = " DST" if $isdst;
  debug "local","$s$dst";
  return $s; }

sub loc2utc6 {
  my $y = $_[0];
  my $m = $_[1];
  my $d = $_[2];
  my $H = $_[3];
  my $M = $_[4];
  my $S = $_[5];
  debug "parsed","$y-$m-$d $H:$M:${S}";

  # localtime
  my $epoch = timelocal_nocheck($S,$M,$H,$d,$m-1,$y);
  my ($ly,$lm,$ld,$lH,$lM,$lS,$isdst) = (gmtime($epoch))[5,4,3,2,1,0,8];
  $ly += 1900;
  $lm += 1;

  # formatting
  my $s = sprintf "%04d-%02d-%02d %02d:%02d:%02dZ",$ly,$lm,$ld,$lH,$lM,$lS;
  my $dst; $dst = " DST" if $isdst;
  debug "local","$s$dst";
  return $s; }

# input: line, output: line with all times converted from utc to localtime
sub utc2loc {
  my $utc = $_[0];
  $utc =~ s/\n$//;
  debug "input",$utc;

  my ($y,$m,$d,$H,$M,$S);
  my $n=0; # index of time string
  my @ts;  # array of time replacement strings

  # parser
  my $RE = qr(([0-9]{4})-([01]?[0-9])-([0-3]?[0-9])\h+([0-2]?[0-9]):([0-5]?[0-9])(:([0-6]?[0-9]))?Z?);
  while($utc =~ /(?:\h|^)($RE)(?=\h|$)/) {
    my $q   = quotemeta $1;
    $ts[$n] = utc2loc6($2,$3,$4,$5,$6,$8);
    $utc =~ s/$q/__TIME${n}__/; $n++; }

  # compiler
  for(my $i=0; $i<$n; $i++) {
    $utc =~ s/__TIME${i}__/$ts[$i]/; }

  debug "output",$utc;
  return $utc; }

# input: line, output: line with all times converted from utc to localtime
sub loc2utc {
  my $loc = $_[0];
  $loc =~ s/\n$//;
  debug "input",$loc;

  my ($y,$m,$d,$H,$M,$S);
  my $n=0; # index of time string
  my @ts;  # array of time replacement strings

  # parser
  my $RE = qr(([0-9]{4})-([01]?[0-9])-([0-3]?[0-9])\h+([0-2]?[0-9]):([0-5]?[0-9])(:([0-6]?[0-9]))?Z?);
  while($loc =~ /(?:\h|^)($RE)(?=\h|$)/) {
    my $q   = quotemeta $1;
    $ts[$n] = loc2utc6($2,$3,$4,$5,$6,$8);
    $loc =~ s/$q/__TIME${n}__/; $n++; }

  # compiler
  for(my $i=0; $i<$n; $i++) {
    $loc =~ s/__TIME${i}__/$ts[$i]/; }

  debug "output",$loc;
  return $loc; }

# ---------------------------------------------------------------- TIME2EPOCH

sub time2epoch_ {
  my $y = $_[0];
  my $m = $_[1];
  my $d = $_[2];
  my $H = $_[3];
  my $M = $_[4];
  my $S = $_[5];
  my $isutc = $_[6];

  my $input = sprintf "%d-%02d-%02d %02d:%02d:%02d",$y,$m,$d,$H,$M,$S;
  $input .= "Z" if $isutc;

  # corrections
  my $c=0; # flag: whether corrected
  while($H>=24) { $H-=24; $d++; $c=1; } 
  my $correct = sprintf "%d-%02d-%02d %02d:%02d:%02d",$y,$m,$d,$H,$M,$S;
  $correct .= "Z" if $isutc;

  # localtime
  my $epoch;
  if($isutc) {
    $epoch = timegm_nocheck($S,$M,$H,$d,$m-1,$y); }
  else {
    $epoch = timelocal_nocheck($S,$M,$H,$d,$m-1,$y); }

  $input .= " -> $correct" if $c;
  debug "epoch","$input -> $epoch";
  return $epoch; }

# input: line
# output[0]: line with all times converted from date+time into epoch seconds
# output[1]: whether the last time in the input string was UTC
sub time2epoch {
  my $line = $_[0];
  $line =~ s/\n$//;
  debug "input",$line;

  my $n=0;	# index of time string
  my @ts;	# array of time replacement strings
  my $isutc=0;	# utc or not-utc state of the last input time

  # parser
  while($line =~ /(?:\h|^)($REtime)(?=\h|$)/) {
    my $q   = quotemeta $1;
    $isutc = $10;
    $ts[$n] = time2epoch_($2,$3,$4,$6,$7,$9,$10);
    $line =~ s/$q/__TIME${n}__/; $n++; }

  # compiler
  for(my $i=0; $i<$n; $i++) {
    $line =~ s/__TIME${i}__/$ts[$i]/; }

  debug "output",$line;
  return ($line,$isutc); }


# ---------------------------------------------------------------- EPOCH2TIME

# $timestring = epoch2time($epoch,$isutc)
# no seconds in output!
sub epoch2time {
  my $epoch = $_[0];
  my $isutc = $_[1];
  my $hmonly = $_[2];

  my ($S,$M,$H,$d,$m,$y);
  if($isutc) {
    ($S,$M,$H,$d,$m,$y) = (gmtime($epoch))[0,1,2,3,4,5]; }
  else {
    ($S,$M,$H,$d,$m,$y) = (localtime($epoch))[0,1,2,3,4,5]; }
  $y += 1900;
  $m += 1;

  my $output;
  if($hmonly) {
    $output = sprintf "%d-%02d-%02d %02d:%02d",$y,$m,$d,$H,$M; }
  else {
    $output = sprintf "%d-%02d-%02d %02d:%02d:%02d",$y,$m,$d,$H,$M,$S; }
  $output .= "Z" if $isutc;

  return $output; }

# ---------------------------------------------------------------------------
