LMLML : Library of MultiLingualization for ML

@author YAMATODANI Kiyoshi
@version $Id: README.txt,v 1.4.2.1 2007/03/28 01:48:56 kiyoshiy Exp $

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
