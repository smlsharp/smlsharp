_interface "118_functorlift.smi"
structure S = F (type t = int)
(*
val x = S.f
*)
(*
2011-09-05 katsu

InferTypes produces a wrong type annotation.

After InferTypes:
extern val _.F
           : ['a.
              {TAG('a), SIZE('a)}
              -> ({1: 'a} -> {1: 'a}) -> {1: {'a}s(t32[]) -> {'a}s(t32[])}]
              (******** s is t32 with one extra arg *******)
val $T_a(3) : {1: s(t34[]) -> s(t34[])} =
    (((EXVAR(_.F
             : ['a.
                {TAG('a), SIZE('a)}
                -> ({1: 'a} -> {1: 'a}) -> {1: s(t34[]) -> s(t34[])}])
              (******** s is t34 with no extra arg *******)
      ...

*)


(*
2011-09-05 ohori
This appears to be correct.
*)

(*
2011-09-06 ohori

Refined the code to generate 
  TPCAST(tpexp, ty, loc)
for
  ICTYCAST(calstlist, icexp,loc).

An error is still reported:

bitmapAnormalizatio done
118_functorlift.sml:3.9-3.11: BAEXVAR: unbound external variable _EXVAR(F.f)
118_functorlift.sml:3.9-3.11: BAVAL: type unification failed
	ty1: errorty
	ty2: (s(t34[]) -f14-> s(t34[]))^{G,B}
closureconversion done

*)
