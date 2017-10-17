val () = raise S.E
(* export name of S.E must be "S.E", but 184_exn2.o provides S.E as "E" *)

(*
2011-12-13 katsu

This causes a link error due to mismatch of export names.

Undefined symbols:
  "_SMLN1S1EE", referenced from:
      _SMLN1S1EE$non_lazy_ptr in 184_exn.o
     (maybe you meant: _SMLN1S1EE$non_lazy_ptr)
ld: symbol(s) not found
collect2: ld returned 1 exit status
uncaught exception: Failed: Failed
    raised at: ../toolchain/main/CoreUtils.sml:105.21-105.71

*)

(*
2011-12-15 ohori

The external name "S.E" is changed to the internal name "E" in datatype compilation.

Type Inference:
 ...
val E(1) : exnTag(t13[]) =
 (#1 (($T_a(3) : exnTag(t13[]) * int(t0[])) :(exnTag(t13[]) * int(t0[]))))
   :(exnTag(t13[]))
and F.x(2) : int(t0[]) =
 (#2 (($T_a(3) : exnTag(t13[]) * int(t0[])) :(exnTag(t13[]) * int(t0[]))))
   :(int(t0[]))
exception tag E(2) = E(1) : exnTag(t13[])
export exception S.E(2)
export variable S.x(2) : int(t0[])

Datatype Compiled:
 ...
val F.x(2) : int(t0[]) = #2 _indexof(2, exnTag(t13[]) * int(t0[])) $T_a(3)
val E(5) : exnTag(t13[]) = E(1)
export val E(5)
export val S.x(2)
*)


(*
2011-12-15 ohori
Fixed by propagating path in RECEPORTEXN to TLEXPORTVAR in DataTypeCompilation.
*)
