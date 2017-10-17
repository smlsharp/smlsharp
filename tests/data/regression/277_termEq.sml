(*
val a = List.getItem [] = NONE 
        andalso List.getItem [#"A"] = SOME(#"A", [])
        andalso List.getItem [#"B", #"C"] = SOME(#"B", [#"C"])) ()
val _ = if a then print "OK\n" else print "Ng\n"
(* 2014-01-26 ohori
  Ngがプリントされる．
*)
*)

infix - = ::
val op - = SMLSharp_Builtin.Int32.sub_unsafe

fun f 0 x = nil
  | f n x = x :: f (n-1) x

fun g 0 = ()
  | g n = if f 1 #"a" = f 1 #"a" then g (n-1) else raise Fail "BUG"

val _ = f 1000 0wxdeadbeaf
val _ = g 10000000

(*
2014-01-28 katsu

This must not raise any exception but raises Fail "BUG".
*)

(*
2014-01-28 katsu

fixed by changeset ff86c77d6199
*)
