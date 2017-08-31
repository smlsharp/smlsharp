structure CharVectorSlice
:> sig
  type t
  val f : t -> int
end
=
struct
  type t = string * int
  fun f ((_,i):t) = i
end

(*
2011-08-25 katsu

This causes BUG at InterTypes.

[BUG] EvalITy: non dty tfun in evalTfun
    raised at: ../types/main/EvalIty.sml:60.16-60.46
   handled at: ../typeinference2/main/InferTypes.sml:1830.63
                ../typeinference2/main/InferTypes.sml:3479.28
                ../toplevel2/main/Top.sml:766.65-766.68
                ../toplevel2/main/Top.sml:868.37
                main/SimpleMain.sml:359.53
*)

(*
2011-08-27 ohori

FIXED by 2665:c5277fe20d37.

Since the implementation type of an opaque type may be a defined type
(TFUN_DEF), TFUN_DEF need to be kept in dtykind. So it is refined to:

  and dtyKind
    = DTY
    | OPAQUE of {opaqueRep:opaqueRep, revealKey:revealKey}
    | BUILTIN of BuiltinType.ty

  and opaqueRep 
    = TYCON of tyCon 
    | TFUNDEF of {iseq:bool, arity:int, polyTy:ty}

where polyTy in TFUNDEF represents a type function (\formals =>
realizerTy) as a polytype of the form [formals. realizerTy].
revealTy performs type-beta by instantiation.

One issme remains. Since now dtykind contain a type, the following
function

  fun runtimeTyOfDtykind opaqueRep =

must be refined to:

  fun runtimeTyOfOpaqueRep opaqueRep =
      case opaqueRep of
        Types.TYCON tyCon => runtimeTyOfTyCon tyCon
      | Types.TFUNDEF {iseq, arity, polyTy} => 
        raise Control.Bug "FIXME"

here we cannot use runtimeTy to polyTy since it is Types.ty not
AnnotatedTypes.ty.

This can be solve by converting dtykind in static analysis.
I have tried to re-write, but the amount of code is unreasonably 
large and had to stop.

*)

(*
2011-08-29 katsu

I added an ad-hoc implementation of the case for Types.TFUNDEF to
TypeLayout.runtimeTy.

*)
