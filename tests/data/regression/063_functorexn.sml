functor F () =
struct
 exception E
end
structure S = F()

(*
2011-08-24 katsu

This causes an unexpected non-exhaustive warning,

063_functor.sml:5.15-5.17 Warning:
  binding not exhaustive
           (E(1)  :exn(t10)) => ...

and BUG at DatatypeCompilation due to undefined exception.

[BUG] switchExn
    raised at: ../datatypecompilation/main/DatatypeCompilation.sml:729.48-729.71
   handled at: ../toplevel2/main/Top.sml:868.37
                main/SimpleMain.sml:359.53

val F(1) : {1: {} -> {}} -> {1: exn(t10)} =
    (fn {$T_a(3) : {1: {} -> {}}} => let exception E(0) in {1 = E(0)} end)
val $T_b(4) : {} =
    (let
       bind caseExp($T_e)(7) : {1: exn(t10)} =
         (F(1) {1 = fn {id(2) : {}} => id(2)})
     in
       (let
          bind $T_g(9) : exn(t10) = #_indexof(1, {1: exn(t10)}) caseExp($T_e)(7)
        in
          (* !!!!!!!! E(1) IS NOT DEFINED !!!!!!!! *)
          (caseExn $T_g(9) of E(1) => {} | _ => raise Bind)
        end)
     end)
*)

(*
2011-08-26 katsu

This was due to lack of exception handling feature with functor.
It works after changeset 9d1e72a6e2ba.

*)
