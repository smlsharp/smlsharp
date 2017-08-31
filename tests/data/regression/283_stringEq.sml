val x = SOME #"\001" = Char.fromString (Char.toString #"\001");
case x of true => () | _ => raise Fail "ng";
(* 2014-01-26 ohori
結果がfalseとなる．
*)

(*
2014-01-29 katsu

fixed by changeset ff86c77d6199
*)
