val f = ref (fn x => (0, x:int))

(*
2011-09-07 katsu

This causes a type diagnosis error due to RecordUnboxing.

133_recordunboxing.sml:1.9-1.32: BAPRIMAPPLY: arg: type unification failed
        ty1: (int(t0[]) -f0-> {$01: int(t0[]), $02: int(t0[])}^{G,B,A})^{G,B}
        ty2: (int(t0[]) -f3-> {int(t0[]), int(t0[])})^{U,B}

after StaticAnalysis:

val f(0)
    : (int(t0[]) -f4-> {1: int(t0[]), 2: int(t0[])}^{G,B,A})^{G,B} ref(t17[]) =
    cast(_PRIMAPPLY((Ref_alloc : ['t35.(t35 -f2-> (t35) ref(t17[]))^{G,B}]))
           (*** instTy have annotation "U" but have "G,B,A" actually ****)
           ((int(t0[]) -f3-> {1: int(t0[]), 2: int(t0[])}^{U})^{U,B})
           ((fn x(1) : int(t0[]) =>
                {1= 0, 2= x(1) : int(t0[])}^L0
                : {1: int(t0[]), 2: int(t0[])}^{G,B,A})^L1
            : (int(t0[]) -f0-> {1: int(t0[]), 2: int(t0[])}^{G,B,A})^{G,B})
         : (int(t0[]) -f1-> {1: int(t0[]), 2: int(t0[])}^{G,B,A})^{G,B}
           ref(t17[])
         : (int(t0[]) -f4-> {1: int(t0[]), 2: int(t0[])}^{G,B,A})^{G,B}
           ref(t17[]))
*)

(*
2011-09-07 katsu

Fixed by changeset ce6362bfb2e3.
*)
