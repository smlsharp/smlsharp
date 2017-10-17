_interface "130_recordunboxing.smi"
fun f () = (1,2)

(*
2011-09-07 katsu

Records which is returned by exported functions must not be unboxed.

StaticAnalysis:

val f(0) : (unit(t7[]) -f0-> {1: int(t0[]), 2: int(t0[])}^{L0})^{L1} =
    (fn $T_a(1) : unit(t7[]) =>
        {1= 1, 2= 2}^L0 : {1: int(t0[]), 2: int(t0[])}^{L0})^L1
    : (unit(t7[]) -f0-> {1: int(t0[]), 2: int(t0[])}^{L0})^{L1}
export val f(0) : (unit(t7[]) -f1-> {1: int(t0[]), 2: int(t0[])}^{G,B,A})^{G,B}

Record Unboxing:

val $3(3) =
  fn^L1 : ((unit(t7[]) -f0-> {int(t0[]), int(t0[])})^{L1}) {$T_a(1)} =>
    {1, 2}
    (******* must not be unboxed ******)

*)

(*
2011-09-07 katsu

Fixed by changeset d29be6a3a842.
Since static analysis performs type inference again, we need to
discard type annotations of EXPORTVAR and look up variables from the
context instead.
*)
