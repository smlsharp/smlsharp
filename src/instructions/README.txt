Instruction definition generation

$Id: README.txt,v 1.1 2006/12/19 13:09:36 kiyoshiy Exp $
$Author: kiyoshiy $

This document describes the detail of generating source codes about bytecode instructions.

====================
Overview

 Configuration in this directory is as follows:

  develop
    +-- src
          +-- instructions
                +-- Instructions.sml.in
                +-- Makefile
                +-- compiler
                |     +-- main
                |           +-- INSTRUCTION_SERIALIZER.sig.in
                |           +-- InstructionSerializer.sml.in
                |           +-- Instructions.sml.in
                +-- runtime
                      +-- main
                            +-- Instructions.cc.in
                            +-- Instructions.hh.in

 First, by running the make command at ../primitives directory, an anchor text in Instructions.sml.in is replaced with decfinitions of primitive operator instructions to generate Instructions.sml.
 Then, by running the make command at this directory, source files are generated from a instruction declaration file (Instructions.sml) and templates files (*.in).

            ../primitives/primitives.csv 
                        |
                        |
                        V
  Instructions.sml.in -----> Instructions.sml
                                  |
                                  |
                                  V
  INSTRUCTION_SERIALIZER.sig.in ------> INSTRUCTION_SERIALIZER.sig
  InstructionSerializer.sml.in  ------> InstructionSerializer.sml
  Instructions.sml.in           ------> Instructions.sml
  Instructions.cc.in            ------> Instructions.cc
  Instructions.hh.in            ------> Instructions.hh

====================
Instructions declaration file

 SML# bytecode instructions are defined in Instructions.sml.in .
It contains a datatype declaration in SML syntax.

 Example:

  -------(Instructions.sml.in)------------
  structure Instructions =
  struct

    datatype instruction =
           (* store an integer into a frame slot. *)
           LoadInt of
           {
             (* an integer value *)
             value : SInt32,
             (* the offset of a frame slot into which the integer is stored. *)
             destination : UInt32
           }
  ----------------------------------------


====================
Template files

 The *.in files in the compiler and runtime directory are templates, from which source files are generated.
Following anchor texts in these template files are replaced with declarations generated from Instructions.sml.

  @CEnumDeclaration@
  @CInstructionToStringFunction@
  @SMLDatatypeDeclaration@
  @SMLOpcodeDatatypeDeclaration@
  @SMLGetSizeOfInstructin@
  @SMLEmitInstruction@
  @SMLInstructionTypeName@
  @SMLInstructionStructureName@
  @SMLInstructionToStringFunction@
  @SMLOpcodeToStringFunction@
  @SMLEqualInstructionFunction@
  @SMLWordToOpcodeFunction@
  @SMLOpcodeToWordFunction@

About meaning of each of these, refer generator/InstructionGenerator.sml, sorry.
