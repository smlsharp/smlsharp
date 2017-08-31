exception E
fun f () = () handle E x => ()

(*
2013-07-02 katsu

This causes an uncaught exception.
This should cause a type error.

uncaught exception: TypesBasics.CoerceFun: TypesBasics.CoerceFun

*)
(*
2013-07-03 ohori
Fixed by 5220:9402a8613434.

*)
