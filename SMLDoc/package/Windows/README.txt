
This directory contains files to make the SMLDoc installer for Windows.

Inno Setup is required.

   http://www.jrsoftware.org/isinfo.php

1) make SMLDoc and install to somewhere.

   $ make mlton

3) copy files to ./files directory.

  1) copy executable files from $(prefix)/bin to ./files/bin.

  At least, following files should be there.

  files
    +-- bin
          +-- smldoc.exe

4) Run make at this directory.
  You need specify ISCC program path.

   $ make ISCC="C:/SiteEx/Inno\ Setup/5/iscc.exe"

  Maybe, you encounter an error, such that "process cannot access file ..."
  This happens once every two running make. (Why ?)
  You should try once again.

5) SMLDoc installer is generated at Output directory.

  Output/smldoc-setup.0.20.exe
