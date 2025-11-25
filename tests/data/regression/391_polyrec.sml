infix polyrec
datatype t = polyrec of int * int
val _polyrec y = 1 polyrec 2

(*
2025-11-25 katsu

This must not cause syntax error.

tests/data/regression/391_polyrec.sml:3.5-12 Error:
  syntax error: replacing  U_POLYREC with  OP
*)
