type t = unit
val count = ref 0
val c = ()
fun foo () = (count := !count + 1; (fn _ => (), fn _ => ()))
fun bar () = #1 (foo ())
