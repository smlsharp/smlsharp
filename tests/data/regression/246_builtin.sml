functor F () =
struct
  val toIntX = SMLSharp_Builtin.Word32.toInt32X  (* builtin *)
end

(*
2012-11-15 katsu

This causes an unexpected mismatch error.

246_builtin.smi:1.9-4.3 Error:
  (name evaluation CP-720) Provide check fails (functor body signature
  mismatch): F
*)
(*
2012-11-17 ohori

Fixed by adding bindBuiltin in NameEval.sml This function changed IDBUILTINVAR 
to IDVAR by generating an extra assignment.
*)

