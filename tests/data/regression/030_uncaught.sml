exception Failure of string;
fun failwith s = raise (Failure s)
fun f x = (failwith "fail") handle Failure "success" => ()
val y = f()

(*
2011-08-17 ohori

The code fails at runtime.
./030_uncaught
セグメンテーション違反です

Note:

This is a part of the bug exibited by knuth-bendix before fixing the
bug 025_equal.sml; if kb fails in completion, it raise an exception
inside of a function, which kb does not catch and should result in
this fault.

*)

(*
2011-08-21 katsu

Fixed.
This is same as 027_raise.
*)
