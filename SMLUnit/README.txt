SMLUnit 

@author YAMATODANI Kiyoshi
@version $Id: README.txt,v 1.5 2007/04/12 05:51:16 kiyoshiy Exp $

 This directory contains SMLUnit.
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

  sources.cm
    description file for CM of SML/NJ.
    To use the SMLUnit in your project, add reference to this file in your cm
   file.

  doc/
    documents

  doc/api/
    SMLUnit API documents in HTML format

  example/
    simple dictionary module and test cases for this module.


========================================
Install

copy this directory to the install directory.

sources.cm must be at the top of the install directory.
Other packages, including SMLFormat and SMLDoc, assume that this file is there.

========================================
References

JUnit (Unit testing framework for Java)
http://www.junit.org/index.htm

OUnit
http://home.wanadoo.nl/maas/ocaml/

HUnit (Unit testing framework for Haskell)
http://hunit.sourceforge.net/

===============================================================================
