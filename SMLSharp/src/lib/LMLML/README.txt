LMLML : Library of MultiLingualization for ML

@author YAMATODANI Kiyoshi
@version $Id: README.txt,v 1.6 2007/04/12 05:54:06 kiyoshiy Exp $

 This directory contains LMLML.
LMLML is a library for multi-byte string manipulation.
'LMLML' is an abbreviation of Library of MultiLingualization for ML.

 This software has been developed as a part of the SML# project.
It is distributed under the BSD-style SMLSharp license, which is
included in the file LICENSE in this directory.

 For the details of SML# project, consult the web page at:
  http://www.pllab.riec.tohoku.ac.jp/smlsharp/

====================
Files

  LMLML
    +-- doc
    |     +-- api
    +-- main
    +-- basis
    +-- test
    +-- SMLDocOptions.txt
    +-- sources.cm
    +-- sources.mlb
    +-- sources.sml

====================
Usage

- SML/NJ

 Use sources.cm with SML/NJ CM.

- MLton

 Use sources.mlb with MLton Basis system.

- SML#

 LMLML is installed with SML# system.
And, its core modules are loaded in prelude.

 In current version of SML#, Codec functor is not loaded in prelude for an implementation reason. To use Codec functor to extend LMLML with new codec, you have to load "LMLML/extension.sml" as follows.

  # use "LMLML/extension.sml";

====================
Documentation

Run smldoc with smldoc.cfg.

  $ smldoc -a smldoc.cfg

HTML files are generated at doc/api .
See doc/api/index.html .

====================
