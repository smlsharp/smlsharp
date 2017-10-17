_interface "102_functorprovide.smi"
functor F() =
struct
  val x = 1
end

(*
2011-09-02 katsu

This causes an unexpected name error.

102_functorprovide.smi:3.11-3.13 Error:
  (name evaluation 0621) unbound type constructor or type alias: int
*)

(*
2011-09-02 ohori

Fixed.

*)
