val f = bar ()
val _ = f c
val _ = f c
val s = Dynamic.format {count = !count};
val _ =
    case s of
      "{count = 1}" =>
      ()
    | _ => raise Fail "CoerceRank1.coerce bug: rank1 instantiation application"
(*
Due to the bug of CoerceRank1.coerce
*)
