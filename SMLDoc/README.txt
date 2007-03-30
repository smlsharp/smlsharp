SMLDoc : Document Generator for Standard ML

@author YAMATODANI Kiyoshi
@version $Id: README.txt,v 1.8 2006/02/23 05:27:47 kiyoshiy Exp $

 The SMLDoc is a tool for generating API documentation in HTML format from
doc comments in source code written in Standard ML.

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
