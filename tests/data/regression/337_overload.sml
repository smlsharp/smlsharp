fun f x = (fn y => overloaded x; ())

(*
2017-02-03 katsu

This causes BUG.

TAG(FREEBTV(142))
uncaught exception: Bug.Bug: generateInstance at src/compiler/recordcompilation/main/RecordCompilation.sml:521
*)
