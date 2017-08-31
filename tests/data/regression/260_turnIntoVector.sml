structure Array = SMLSharp_Builtin.Array
val buf = Array.alloc 0
val _ = (_import "puts" : string -> int) "hoge2\n";
val _ = Array.turnIntoVector buf

(*
2013-07-08 katsu

This causes segmentation fault.

hoge2

Segmentation fault: 11

*)
(*
2013-01-26 katsu

The above error does not occur on the latest LLVM backend.
*)
