Primitive generation

This document describes the detail of generating source codes about primitive operators.

====================
Overview

 Configuration in this directory is as follows:

  develop
    +-- src
          +-- primitives
                +-- primitives.csv
                +-- Makefile
                +-- compiler
                |     +-- main
                |           +-- Primitives.sml.in
                +-- runtime
                      +-- main
                            +-- Primitives.cc.in

 By running the make command with the Makefile, source files are generated from a primitives declaration file (primitives.csv) and templates files (*.in).

               primitives.csv
                       |
                       |
                       V
  Primitives.sml.in ------> Primitives.sml
  Primitives.cc.in  ------> Primitives.cc

====================
Primitives declaration file

 Informations about primitive operators are to be described into the primitives.csv in the CSV format.
Each line in the primitives.csv contains 5 fields (more fields may be added in future). They are:

  1, binding name in SML program
  2, type expression
  3, arity (= the number of arguments)
  4, opcode, if a bytecode instruction is dedicated for this primitive
  5, name of C function implementing this primitive, otherwise

 The third field and the fourth field are mutually exclusive. Either field should be specified, but it is error if both are specified.

 Example:

  =======(primitives.csv)=================
  print,"string -> unit",1,,IMLPrim_print
  +,"int * int -> int",2,ADDINT,
  ========================================

Three primitives are listed in this example. Among these primitives, 'print' and 'getDate' are implemented by external C functions, while '+' is executed by an instruction 'ADDINT'.

====================
Template files

 The *.in files in the compiler and runtime directory are templates, from which source files to be compiled are generated.

  =======(Primitives.sml.in)==============
  structure Primitives =
    val primitives =
        [
          @SMLPrimitives@
        ]
  end
  ========================================

  =======(Primitives.cc.in)===============
  const Primitive primitives =
  {
    @CPrimitives@
  };
  ========================================

 '@SMLPrimitives@' and '@CPrimitives@' embedded in the texts are anchors which is replaced with SML or C code snip generated from the primitives.csv.

 From above primitives.csv and these templates, the following source codes are generated.

  =======(Primitives.sml.in)==============
  structure Primitives =
    val primitives =
        [
          ("print", "string -> unit", 1, ExternalPrimitive 1),
          ("+", "int * int -> int", 2, InternalPrimitive ADDINT),
        ]
  end
  ========================================

  =======(Primitives.cc.in)===============
  const Primitive primitives =
  {
    {1, IMLPrim_print}
  };
  ========================================

NOTE: Actual code will be different from this example.
