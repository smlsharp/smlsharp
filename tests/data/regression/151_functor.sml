functor F () =
struct
  datatype set = EMPTY | TREE of set * set
end

(*
2011-11-28 katsu

This causes an unexpcted name error.

151_functor.smi:1.9-4.3 Error:
  (name evaluation CP-431) Provide check fails (functor body signature mismatch)
  : F

*)

(*
2011-11-28 ohori

fixed

*)
