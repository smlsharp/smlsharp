_interface "265_functor.smi"
functor F () =
struct
  structure T = S
end
structure S2 = F()

(*
2013-7-26 ohori

This causes a bug exception.

2013-7-26 ohori
Fixed by 5287:1ee701ddd7ef
*)
