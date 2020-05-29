val _ = (raise E1) handle E2 => ()

(*
2018-04-26 katsu

When linking:
Undefined symbols for architecture x86_64:
  "__SMLZ2E2", referenced from:
      __SML_main53814d1fd4f311a4_345_exnrep in 345_exnrep.o
*)
