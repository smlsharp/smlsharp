functor F(A : sig type t end) =
struct
  type s = A.t
  datatype 'b bar = B of A.t
  datatype 'c car = C of s
end

(*
2011-09-11 katsu

This causes BUG.

[BUG] NameEval (FunctorUtils): TSTR_TOTVAR in sig
    raised at: ../nameevaluation/main/FunctorUtils.sml:745.38-745.62
   handled at: ../nameevaluation/main/FunctorUtils.sml:816.27
                ../nameevaluation/main/FunctorUtils.sml:816.27
                ../nameevaluation/main/CheckProvide.sml:1110.43
                ../nameevaluation/main/CheckProvide.sml:1122.59
                ../nameevaluation/main/NameEval.sml:2537.31
                ../nameevaluation/main/NameEval.sml:2549.27-2549.30
                ../toplevel2/main/Top.sml:753.66-753.69
                ../toplevel2/main/Top.sml:836.37
                main/SimpleMain.sml:368.53
*)

(*
2011-11-25 ohori

Fixed by chnaging the strategy of lifting type decls in functor args.
 type foo
in functor argument is now compiled to \().'a and TFUN_TOTVAR is eliminated.

*)
