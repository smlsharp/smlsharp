mlb2use

 mlb2use is a utility to generate 'use' directives from MLton mlb files.

@author YAMATODANI Kiyoshi
@version $Id: README.txt,v 1.1 2007/07/29 08:12:03 kiyoshiy Exp $

-----
Build.

  $ cd iml2/develop/src/tool/mlb2use/
  $ make
  $ make install

-----
Usage.

 'mlb2use' command takes two arguments. A path-map file and a mlb file.

  $ cat > smlsharp-path-map.txt
  SML_LIB ${SML_LIB}
  CONFIGDIR ${CONFIGDIR}
  ARCH cygwin
  BYTE_ORDER Little
  ^D

  $ mlb2use \
        smlsharp-path-map.txt \
        ../../compiler/commands/smlsharp/main/sources.mlb \
        > smlsharp.use

This generates a SML source file 'smlsharp.use'.
It consists of 'use' directives to load source files which are referred from the argument mlb file.

Specify '-h' to see options.

 $ ./mlb2use -h
 mlb2use [-d baseDir] [-p pathMapFile] [-e] [-v] MLBfile
   -d baseDir      converts paths to relative to baseDir.
   -p pathMapFile  uses a path-map file.
   -e              excludes absolute paths from output.
   -v              runs in verbose mode.

-----