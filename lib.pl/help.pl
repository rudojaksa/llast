# ------------------------------------------------------------------------------------ HELP
my $helpdebug=<<EOF;
DEBUG
    Debug messages can be switched on/off by strains.
    Available strains are:
    ${CC_}_STRAINS_$CD_.

    $CC_-d STRAIN$CC_\[,STRAIN...\]$CD_ Debug only specified strains.
    $CC_-d -STRAIN$CD_ Prefix the strain with "-" to avoid it.
EOF
# -----------------------------------------------------------------------------------------

sub printhelp {
  my $help = $_[0];

  # commented-out
  $help =~ s/(\n\#.*)*\n/\n/g;

#  my $debug_strains = debug_strains_list();
#  $debug_strains =~ s/, /$CD_, $CC_/g;
  $help =~ s/_DEBUG_\n/$helpdebug/;
  $help =~ s/_STRAINS_/$debug_strains/;

  $help.="VERSION\n    $PACKAGE.$VERSION $COPYLEFT\n\n";

  # CC(text)
  $help =~ s/([^A-Z0-9])CC\((.+?)\)/$1$CC_$2$CD_/g;
  $help =~ s/([^A-Z0-9])CW\((.+?)\)/$1$CW_$2$CD_/g;
  $help =~ s/([^A-Z0-9])CD\((.+?)\)/$1$CD_$2$CD_/g;

  # TODO: use push array to avoid being overwritten later
  $help =~ s/(\n[ ]*)(-[a-zA-Z0-9]+(\[?[ =][A-Z]{2,}(x[A-Z]{2,})?\]?)?)([ \t])/$1$CC_$2$CD_$5/g;

  $help =~ s/\[([+-])?([A-Z]+)\]/\[$1$CC_$2$CD_\]/g;
  $help =~ s/(\n|[ \t])(([A-Z_\/-]+[ ]?){4,})/$1$CC_$2$CD_/g;

  print $help; }

# -----------------------------------------------------------------------------------------
