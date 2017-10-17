functor F(
  A : sig
    val f : 'a * 'b -> 'b * 'a
  end
) =
struct
end

(*
2011-11-29 katsu

This causes an unexpected name error.

161_functorarg.smi:1.9-7.3 Error:
  (name evaluation CP-430) Provide check fails (functor parameter signature
  mismatch) : F

*)


(*
2011-11-29 ohori

Elaborator is changed so that in the interface dec;
 PLSPECVAL of scopedTvars * string * ty * loc (* value *)
the order of type variables in  scopedTvars is that of occurrance in ty.

*)
