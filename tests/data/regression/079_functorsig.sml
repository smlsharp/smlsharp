functor F (
  eqtype t2
  val f : t2 -> int
) :>
sig
  eqtype t1
  val f : t1 -> int
end
where type t1 = int
= struct
    type t1 = t2
    val f = f
end

(*
2011-08-27 katsu

This causes BUG at NameEval.
An type error is expected.

[BUG] NameEval: TFUN_VAR
    raised at: ../nameevaluation/main/NameEval.sml:957.26-957.40
   handled at: ../nameevaluation/main/NameEval.sml:2878.31
		../nameevaluation/main/NameEval.sml:2897.27-2897.30
		../toplevel2/main/Top.sml:756.66-756.69
		../toplevel2/main/Top.sml:868.37
		main/SimpleMain.sml:359.53
*)


(*
2011-08-29 ohori

Fixed. 

I had better review the error case of CheckTfun in sigCheck.

*)
