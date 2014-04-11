SMLUnit 

@author YAMATODANI Kiyoshi
@version $Id: README.txt,v 1.5 2007/04/12 05:51:16 kiyoshiy Exp $

 SMLUnit is a unit testing framework for Standard ML.
SMLUnit is a simple framework and its specification is similar to HUnit,
OUnit, JUnit and other xUnit frameworks.

 This software has been developed as a part of the SML# project.
It is distributed under the BSD-style SMLSharp license, which is
included in the file LICENSE in this directory.

 For the details of SML# project, consult the web page at:
  http://www.pllab.riec.tohoku.ac.jp/smlsharp/

========================================
Files/Directories

  src/
    source files of SMLUnit

  sources.{sml,cm,mlb}
    loader scripts for SML#, SML/NJ and MLton.

  doc/
    documents

  doc/api/
    SMLUnit API documents in HTML format

  example/
    simple dictionary module and test cases for this module.


========================================
Usage

Loader scripts are provided for SML#, SML/NJ and MLton.

SML#: 
  smlunitlib.sml

SML/NJ: 
  smlunitlib.cm

MLton: 
  smlunitlib.mlb

To use the SMLUnit in your project, add reference to these files in your
project files.

========================================
References

JUnit (Unit testing framework for Java)
http://www.junit.org/index.htm

OUnit
http://home.wanadoo.nl/maas/ocaml/

HUnit (Unit testing framework for Haskell)
http://hunit.sourceforge.net/

===============================================================================
