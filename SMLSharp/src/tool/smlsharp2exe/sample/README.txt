@version $Id: README.txt,v 1.2 2008/01/13 02:54:49 kiyoshiy Exp $
@author YAMATODANI Kiyoshi

This is a sample program which links a C code with an object file generated from SML# code.

Build.

  $ make \
      SMLSHARP2EXE=/home/yamato/tmp/release/bin/smlsharp2exe.sh \
      SMLSHARP_LIB_DIR=/home/yamato/tmp/release/lib/

Specify SMLSHARP2EXE and SMLSHARP_LIB_DIR according to your SML# installation.
It generates app.exe.

  $ ./app.exe
  doOpen(hoge)
  result = 1

app.exe is generated from 2 source files.
  app.c
  interpreter.sml
'main' function in app.c calls 'eval' function defined in interpreter.sml, which calls 'doOpen' function defined in app.c .
