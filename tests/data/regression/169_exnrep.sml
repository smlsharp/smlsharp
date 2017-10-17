functor F(
  A : sig
    exception E
  end
) =
struct
  exception E1 = A.E
  exception E2 = E1
end

(*
2011-11-30 katsu

This causes an unexpected name error.

169_exnrep.smi:8.13-8.19 Error:
  (name evaluation EI-150) undefined exception id : E1

*)

(*
2011-11-30 ohori
Fixed by adding the missing case for origId to be IDEXNREP in NameEvalInterface.
*)
