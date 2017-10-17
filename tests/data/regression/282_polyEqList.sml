val S = "a";
val a = explode S;
val b = explode S;
val x = a = b;
case x of true => () | _ => raise Fail "ng";
(* 2014-01-26 ohori
a = bの結果がfalseとなる．
val S = "a" : string
val a = [#"a"] : char list
val b = [#"a"] : char list
val it = false : bool
*)

(*
2014-01-29 katsu

fixed by changeset ff86c77d6199
*)
