functor F(
  A : sig
    exception E
  end
) =
struct
  open A
end

(*
2011-11-30 katsu

This causes an unexpected mismatch error.

170_functorexn.smi:1.9-8.3 Error:
  (name evaluation CP-431) Provide check fails (functor body signature mismatch)
  : F
*)

(*
2011-11-30 ohori

Fixed by apply exceptionRepEnv to the result of opend structure
in evalPdecl.

Note: the original 170_functorexn.smi has an error (exception name is meant to be E),
which is corrected.

*)
