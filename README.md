### NAME
llast - list last modified files

### USAGE
        llast [OPTIONS] FILE|DIR ...

### DESCRIPTION
List files and symlinks with the ISO 8601 timestamp in the order
of the last modification (last=first).  It is ls-wrapper preserving
the coloring of filenames.  For Linux and Mac.

<p align=center><img src=test/sshot/1.png width=580></p>

### OPTIONS
          -h  This help.
          -v  Verbose execution using STDERR.
          -l  Long output (now alias for -sm)
          -8  Print only the first 8 files.
         -nc  No-colors output.
        -md5  Include md5 column.
         -lo  Look into locate database.

### SCOPE
        By default, recursive list of files and symlinks is provided.  Symlinks
        are not followed.  Paths searched by -p or -re might start with the "./",
        depending on the requested starting FILE/DIR.  Default start dir is ".".
    
          -d  Print directories too.
          -f  Files only (no symlinks).
    
      -n PAT  Filename glob pattern (e.g. *.c), more -n are or-combined.
      -p PAT  Path glob pattern.  The -n and -p are and-combined.
     -re PAT  Path regex pattern.
     -np PAT  Skip directory-path.
    -nre PAT  Skip regex directory-paths.
          -i  Case insensitiveness for regex and glob.
    
         -nr  No recursion (same as -r1)
         -r2  Max recursion 2 (-r0 means not even this directory).
       -r2-3  Recursion from level 2 to 3.
        -r=2  Only level 2 paths.

### TIME
        Sub-second precision of time is used for the ordering of files,
        unless the -min switch is used, but only the minutes precision
        is printed by default.
    
        -min  Use only minutes precision (skip seconds).
        -sec  Print seconds too.
        -sub  Print sub-seconds.
      -epoch  Print UNIX epoch time.
         -nt  Don't print time.

### SIZE
        Output filesize delimiters are: k for kilo or kibi, M for mega
        or mebi, G for giga or gibi.
    
          -s  Print file-size.
         -sk  Print file-size in kibibytes (KiB).
         -sm  In mebibytes (MiB).
         -sg  In gibibytes (GiB).
        -met  Metric output (1000-based MB, not 1024-based MiB).
         -sK  Metric output (also -sM -sG).
        -sk0  Integer output, no decimals (also -sm0 -sg0 -sK0 -sM0 -sG0).

### ORDER
        By default, newest items are listed first.  Multiple sorting criteria
        can be used, they are combined according to the rank.
    
          +t  Time order (default).
          +s  Size order.
          +a  Alphabetical order.

### INSTALL
        To install copy the llast and ll into your /bin directory.

### VERSION
llast.0.2 (c) R.Jaksa 2018 GPLv3

