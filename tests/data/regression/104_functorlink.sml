_interface "104_functorlink.smi"
val _ = (_import "puts" : string -> int) "1"
structure T = F()

(*
2011-09-02 katsu

This causes bus error at runtime due to external name conflict.
"val F : unit" in 104_functorlink2.smi and "functor F" in
104_functorlink3.smi have same external path ["F"].
Since global variables are allocated in the common section,
linker does not complain about symbol conflict.

$ smlsharp -c 104_functorlink.sml
$ smlsharp -c 104_functorlink2.sml
$ smlsharp -c 104_functorlink3.sml
$ smlsharp 104_functorlink.smi
$ ./a.out
2
3
1
Bus Error

*)


(*
2011-09-02 ohori

Fixed.

This occurs because the name space for functors and that of variables
are merged into one in name evaluation.

A tentative solution is to prefix a functor name with some special 
symbol ("_.") to genreate the variable representation.

*)


