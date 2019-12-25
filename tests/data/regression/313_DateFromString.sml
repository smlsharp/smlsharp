val a = Date.fromString "Thu Jan  1 00:00:00 1970"
val b = Option.valOf a
val c = Date.toString b

val _ = case c of
          "Thu Jan  1 00:00:00 1970" => ()
        | "Thu Jan 01 00:00:00 1970" => ()
        | _ => raise Fail "Unexpected"

(*
2014-08-20 Sasaki

This code raises Fail exception unexpectedly since the assertion fails.

表記の違いを考慮。

*)
