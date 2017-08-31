val puts = _import "puts" : string -> int

fun f () = "s"
val _ = 
    case f () of
      "count"  => puts "COUNT"
    | "posarg" => puts "POSARG"
    | "s"      => puts "LEXSTATES"
    | _ => (puts "ng"; raise Fail "ng")

(*
2011-12-17 ohori

case on string does not work. "ng\n" is get printed.
*)

(*
2011-12-18 katsu

fixed by changeset fd71da60d115.

*)
