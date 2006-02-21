SMLFormat (Pretty Printer for SML)

 The SMLFormat consists of two components:
   formatlib (Pretty Printer library for SML)
   smlformat (Pretty Printer Generator for SML)

 The formatlib provides modules for pretty-printing of data structures.
These modules define 
 (a) the type of 'format expression' which is an intermediate code to format
   data into string
 (b) the functions which translate a format expression into its textual
    representation with indented and multilined as appropriate.

 The smlformat is a SML source code processor. It analyses SML source codes
annotated with special comments which specify how to format values of the
types by the format expressions. And it generates definitions of functions
which translate data structures into its representation in the format
expression.

========================================
Directories

  generator/
      The formatter generator.
      It generates SML code of function definition which translates SML values
     into the intermediate form (= 'FormatExpression').

  formatlib/
      The pretty-printer library.
      The FormatExpression which the formatter function generates is translated
     into a text by this library.

  example/

    MLParser/
      A parser of SML core syntax.
      It prints the formatted representation of the SML code you input.

    FormatExpressionParser/
      A parse of format expressions.
      It prints the formatted representation of the format expression you
     input.

========================================
Build

 1) configure
   Specify the directory where SMLUnit is installed.

   $ ./configure SMLUNITDIR=/home/kiyoshiy/IMLProject/SMLUnit

  SMLUNITDIR must be absolute path.

  SMLUNITDIR is optional. If you won't run unit tests, simply:

   $ ./configure

 2) invoke make command

   $ make

 3) a batch file "smlformat" and a heap image file are generated in the bin
   directory.

========================================
Unit test of formatlib

 1) configure with SMLUNITDIR specified.

 2) cd formatlib/test.

   $ cd formatlib/test

 3) start sml session.

   $ sml

 4) compile project

   - CM.make();

 5) run test runner

    - TestMain.test();
    ......................................................................................................................
    tests = 118, failures = 0, errors = 0
    Failures:
    Errors:
    val it = () : unit

===============================================================================




