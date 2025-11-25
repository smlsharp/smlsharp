infix import
datatype t = import of int * int
val _import y = 1 import 2

(*
2025-11-25 katsu

This must not cause syntax error.

tests/data/regression/392_import.sml:3.5-11 Error:
  syntax error: replacing  U_IMPORT with  OP
*)
