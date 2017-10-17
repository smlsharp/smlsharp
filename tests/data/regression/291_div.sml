(*
~1 div 2;
(* 2014-01-27 
# ~1 div 2;
val it = 0 : int

roundingは負無限大方向．
*)
*)

infix div
val op div = SMLSharp_Builtin.Int32.div
val _ = case ~1 div 2 of
          ~1 => ()
        | _ => raise Fail "BUG"

(*
2014-01-28 katsu

rewrote the test code.
*)

(*
2014-01-28 katsu

fixed by changeset 7070201a57b1.
*)
