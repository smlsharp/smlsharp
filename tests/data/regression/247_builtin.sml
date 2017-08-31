functor F () =
struct
  val toIntX = SMLSharp_Builtin.Word32.toInt32X  (* builtin *)
  val foo = SMLSharp_Builtin.Word32.toInt32X  (* builtin *)
end


(*
2012-11-18 ohori
This causes a mismatch error.

246_builtin.smi:1.9-4.3 Error:
  (name evaluation CP-720) Provide check fails (functor body signature
  mismatch): F

This is the current specification of the name evaluation. 
I will consider revising the name evaluator to allow both
variable replication interface and variable type specification interface
in a functor body.
*)

(*
2013-08-07 ohori
Fixed by the major change of introduction of 
SpliceFunProvide.sml
*)
