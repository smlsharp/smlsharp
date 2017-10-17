functor F(
  A : sig
    structure MISMATCHED_NAME : sig end
  end
) =
struct
end

(*
2011-11-29 katsu

This causes BUG.
An name error is expected.

uncaught exception: Fail: Fail
    raised at: ../nameevaluation/main/FunctorUtils.sml:832.31-832.35
   handled at: ../nameevaluation/main/CheckProvide.sml:906.43
                ../nameevaluation/main/CheckProvide.sml:918.25
                ../nameevaluation/main/NameEval.sml:2481.34
                ../nameevaluation/main/NameEval.sml:2493.27-2493.30
                ../toplevel2/main/Top.sml:753.66-753.69
                ../toplevel2/main/Top.sml:836.37
                main/SimpleMain.sml:368.53

*)

(*
2011-11-29 ohori
Fixed
*)
