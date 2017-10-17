_interface "129_functor.smi"
functor F (
  A : sig
    type t
    val f : 'a -> t
  end
) =
struct
  fun f x = x
end
(*
2011-09-06 katsu

This causes an unexpected type error.

129_functor.sml:2.9-9.3 Error:
  (type inference 063-2) type and type annotation don't agree
    inferred type: ({1: 'C('RIGID(tv34))} -> {1: 'C('RIGID(tv34))})
                   -> ['a. 'a -> 'C('RIGID(tv34))] -> unit(t7[])
  type annotation: ({1: 'C('RIGID(tv34))} -> {1: 'C('RIGID(tv34))})
                   -> ['a. 'a -> 'C('RIGID(tv34))] -> unit(t7[])
*)


(*
2011-09-07 ohori

Fixed by the following refinemets.
1. added ICEXPORTFUNCTOR (var, ty, loc) for functor export decl.
2. In ICEXPORTFUNCTOR, ty and the actual functor term are eithr:
 1. TYPOLY(btvs, TYFUNM([first], TYFUNM(polyList, body)))
    ICFNM1([first], ICFNM1_POLY(polyPats, BODY))
 2. TYPOLY(btvs, TYFUNM([first], body))
    ICFNM1([first], BODY)
 3. TYFUNM(polyList, body)
    ICFNM1_POLY(polyPats, BODY)
 4. TYFUNM([unit], body)
    ICFNM1(UNIT, BODY)
 where body is either
    unit (TYCONSTRUCT ..) 
 or
   record (TYRECORD ..)
 BODY is ICLET(..., ICCONSTANT or ICRECORD)
InferType do case analysis and type check accordingly.

*)
