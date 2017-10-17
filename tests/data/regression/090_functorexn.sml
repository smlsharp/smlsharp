functor F () =
struct
  exception E of int 
end
structure S = F()
fun f x = x handle S.E x => x

(*
2011-08-29 katsu

This causes an unexpected name error.

090_functorexn.sml:6.20-6.22 Error:
  (name evaluation 004) constructor expected in a constructor pattern: E ( x)
*)

(*
2011-09-01 ohori

Fixed.

*)
