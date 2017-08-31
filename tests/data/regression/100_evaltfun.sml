structure S : sig
  type t
  val f : t -> unit
end =
struct
  type t = int * int
  fun f (_:t) = ()
end
val _ = S.f

(*
2011-09-02 katsu

This causes BUG at InferTypes.

uncaught exception: EVALTFUN: EVALTFUN
    raised at: ../types/main/EvalIty.sml:63.15-63.75
   handled at: ../types/main/EvalIty.sml:137.45
                ../typeinference2/main/InferTypes.sml:1877.63
                ../typeinference2/main/InferTypes.sml:3670.28
                ../toplevel2/main/Top.sml:766.65-766.68
                ../toplevel2/main/Top.sml:868.37
                main/SimpleMain.sml:359.53
*)


(*
2011-09-02 ohori

Fixed. The fix is rather ad hoc.
In this case tfun is not normal, so I tentatively added
normalization in InferType. I will review this case later.

*)
