val y = (x,x)

(*
2012-09-18 katsu

This causes a link error.

$ smlsharp -c 236_link.sml
$ smlsharp -c 236_link2.sml
$ smlsharp 236_link.smi
Undefined symbols:
  "_SML1x", referenced from:
      _SML1x$non_lazy_ptr in 236_link.o
     (maybe you meant: _SML1x$non_lazy_ptr)
ld: symbol(s) not found
collect2: ld returned 1 exit status
uncaught exception: CoreUtils.Failed: CoreUtils.Failed
*)

(*
2013-01-26 katsu

The above error was fixed on LLVM backend.

*)
