
This directory contains files to make the SML# installer for Windows.

Inno Setup is required.

   http://www.jrsoftware.org/isinfo.php

1) make SML# and install to somewhere.

   $ make
   $ make install

2) copy files from SML# installed directory.
  At least, following files should be there.

  files
    +-- bin
    |     +-- smlsharp.exe
    |     +-- smlsharprun.exe
    |
    +-- lib
    |     +-- prelude.smc
    |
    +-- hello_world.sml

3) Run make at this directory.
  You need specify ISCC program path.

   $ make ISCC="C:/SiteEx/Inno\ Setup/5/iscc.exe"

  Maybe, you encounter an error, such that "process cannot access file ..."
  This happens once every two running make. (Why ?)
  You should try once again.

4) SML# installer is generated at Output directory.

  Output/smlsharp-setup.0.20.exe
