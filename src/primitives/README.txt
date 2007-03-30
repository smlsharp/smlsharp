Primitive operator, constant and predefined types.

$Id: README.txt,v 1.5 2007/02/28 04:26:13 kiyoshiy Exp $
$Author: kiyoshiy $

This document describes the detail of how to add primitive operators, constants and predefined types.

====================
Overview

 Configuration in this directory is as follows:

  develop
    +-- src
          +-- primitives
                +-- primitives.csv
                +-- constants.csv
                +-- Makefile
                +-- compiler
                |     +-- main
                |           +-- Primitives.sml.in
                |           +-- Constants.sml.in
                |           +-- PredefinedTypes.sml
                +-- runtime
                      +-- main
                            +-- Primitives.cc.in
                            +-- Constants.cc.in
                            +-- Constants.hh.in

 By running the make command with the Makefile, source files are generated from a primitives declaration file (primitives.csv) and templates files (*.in).

               primitives.csv
                       |
                       |
                       V
  Primitives.sml.in ------> Primitives.sml
  Primitives.cc.in  ------> Primitives.cc

Similarly, from constant declaration file (constants.csv) and templates files (*.in).

                constants.csv
                       |
                       |
                       V
  Constants.sml.in  ------> Constants.sml

====================
Primitives declaration file

 Informations about primitive operators are described in primitives.csv in the CSV format.
Each line in primitives.csv contains 6 fields. They are:

  1, binding name in SML program
  2, aliase which can be used as a valid identifier in SML and C code.
  3, type expression
  4, arity (= the number of arguments)
  5, opcode, if a bytecode instruction is dedicated for this primitive
  6, name of C function implementing this primitive, otherwise

 The fifth and the sixth fields are mutually exclusive. 
It is error if both are specified.

 Example:

  -------(primitives.csv)-----------------
  print,,"string -> unit",1,,IMLPrim_print
  +,add,"int * int -> int",2,ADDINT,
  :=,update,"['a.('a) ref * 'a -> unit]",2,,
  ----------------------------------------

Three primitives are listed in this example. 
'print' is implemented by external C functions.
'+' is executed by an instruction 'ADDINT'.
':=' is treated specially in compiler, so the fourth and fifth fields are unspecified.
And, arguments of a type constructor must be enclosed by parenthesis.

====================
Template files

 The *.in files in the compiler and runtime directory are templates, from which source files to be compiled are generated.

  -------(Primitives.sml.in)--------------
  structure Primitives =
    @SMLPrimitiveInfos@
    val primitives =
        [
          @SMLPrimitives@
        ]
  end
  ----------------------------------------

  -------(Primitives.cc.in)---------------
  const Primitive primitives =
  {
    @CPrimitives@
  };
  ----------------------------------------

 '@SML...@' and '@C...@' embedded in the texts are anchors which is replaced with SML or C code snip generated from the primitives.csv.

 From above primitives.csv and these templates, the following source codes are generated.

  -------(Primitives.sml.in)--------------
  structure Primitives =
    val printPrimInfo = {name = "print", ty = "string -> unit"}
    val addPrimInfo = {name = "+", ty = "int * int -> int"}
    val updatePrimInfo = {name = ":=", ty = "['a.('a) ref * 'a -> unit]"}
    val primitives =
        [
          ("print", "string -> unit", 1, ExternalPrimitive 1),
          ("+", "int * int -> int", 2, InternalPrimitive ADDINT),
          (":=", "['a.('a) ref * 'a -> unit]", 2, None)
        ]
  end
  ----------------------------------------

  -------(Primitives.cc.in)---------------
  const Primitive primitives =
  {
    {1, IMLPrim_print}
  };
  ----------------------------------------

NOTE: Actual code will be different from this example.

====================
Constants declaration file

 Names of constant integer value which are shared between the compiler and the rumtime are declared in constants.csv file.

  --------(constants.csv)-----------------
  TAG_bool_true,1
  TAG_bool_false,0
  ----------------------------------------

Similar with primitive declaration generation, anchor texts in *.in files are replaced with constant declarations generated from constants.csv.

  --------(Constants.sml.in)--------------
  structure Constants =
  struct

    @SMLConstants@

  end
  ----------------------------------------

The following file is generated.

  --------(Constants.sml)-----------------
  structure Constants =
  struct
    val TAG_bool_true = 1
    val TAG_bool_false = 0
  end
  ----------------------------------------

====================
Adding Predefined type.

 If you need to add a new predefined type, you have to edit following files.

  src/primitives/compiler/main/PredefinedTypes.sml
  src/primitives/constants.csv
  src/lib/basis/main/BasicFormatters.sml
  src/lib/minimum/main/preludes.sml

For example, assume we add a new datatype dt that would be declared in SML syntax as follows.

  datatype 'a dt = C of 'a | D

-----
First, register a type constructor to PredefinedTypes.sml.

  --------(PredefinedTypes.sml)----------
  val (dtTyCon, dtTyConid, NONE) =
      makeTyCon "dt" [false] TY.EQ TY.BOXEDty
  ----------------------------------------

The second argument [false] indicates that dt takes a type parameter which does not require equality.

-----
Then, register value constructors.

A) If these value constructors are not used in runtime source code, addition of them to PredefinedTypes as follows is sufficient.

  --------(PredefinedTypes.sml)----------
  val CCon = makeValCon "C" "['a. 'a -> ('a) dt]" 0
  val DCon = makeValCon "D" "dt" 1
  ----------------------------------------

B) If the runtime source code uses these value constructors, you have to add constructor tags to constants.csv.

  --------(constants.csv)-----------------
  TAG_dt_C,0
  TAG_dt_D,1
  ----------------------------------------

It generates C declarations.

  const int TAG_dt_C = 0;
  const int TAG_dt_D = 1;

Then, add the following lines to PredefinedTypes.sml.

  --------(PredefinedTypes.sml)----------
  val CCon = make "C" "['a. 'a -> ('a) dt]" C.TAG_dt_C
  val DCon = make "D" "dt" C.TAG_dt_D
  ----------------------------------------

-----
Next, define a formatter in BasicFormatters.sml and preludes.sml.

  --------(BasicFormatters.sml)----------
  fun '_format_dt' format_element (C arg) =
      Guard
        (
          NONE,
          [
            Term(1, "C"),
            Indicator{space = true, newline = NONE},
            format_element arg
          ]
        )
    | '_format_dt' format_element D = Term(1, "D");
  ----------------------------------------

You have to write the same definition in preludes.sml also.

