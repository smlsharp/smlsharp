SMLDoc : Document Generator for Standard ML

@author YAMATODANI Kiyoshi
@version $Id: README.txt,v 1.9 2007/04/12 05:48:06 kiyoshiy Exp $

This directory contains SMLDoc.
SMLDoc is a tool for generating API documentation in HTML format from
doc comments in source code written in Standard ML.

This software has been developed as a part of the SML# project.
It is distributed under the BSD-style SMLSharp license, which is
included in the file LICENSE in this directory.

For the details of SML# project, consult the web page at:
  http://www.pllab.riec.tohoku.ac.jp/smlsharp/

========================================
Build

 1) Configure.
  Specify the directory where SMLFormat is installed.

   $ ./configure --with-smlformat=/home/kiyoshiy/IMLProject/SMLFormat

  The path specified in --with-smlformat must be an absolute path.

  If you want to run unit test, specify --with-smlunit also.

   $ ./configure \
            --with-smlformat=/home/kiyoshiy/IMLProject/SMLFormat \
            --with-smlunit=/home/kiyoshiy/IMLProject/SMLUnit

 2) invoke make command

   $ make

 3) a script file "smldoc" and a heap image file are generated in the bin
   directory.
   If you want to move the heap image file to other place, you have to edit
   "smldoc" command to use the new location of the heap image file.


========================================
Unit test

 1) Specify SMLUNITDIR when invoke configuration.


 2) cd src/test.

   $ cd src/test

 3) start sml session.

   $ sml

 4) compile project

   - CM.make();

 5) run test runner

   - TestMain.test();
   ............................
   tests = 28, failures = 0, errors = 0
   Failures:
   Errors:
   val it = () : unit

========================================
NOTE

Some source files in the following directories are borrowed from SML/NJ distribution.

  src/main/HTML
  src/main/getopt/
  src/main/smlnjcm/

========================================
References

JavaDoc  (for Java)
http://java.sun.com/j2se/javadoc/

HDoc  (for Haskell)
http://www.fmi.uni-passau.de/~groessli/hdoc/

Haddoc
http://www.haskell.org/haddock/

OCamlDoc
http://caml.inria.fr/ocaml/htmlman/manual029.html
===============================================================================
