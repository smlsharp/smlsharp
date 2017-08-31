_interface "097_providefun.smi"
functor F (
  A : sig
    val x : int
  end
) =
struct
end

(*
2011-09-01 katsu

This causes an unexpected name error.

097_providefun.smi:3.13-3.15 Error:
  (name evaluation 0621) unbound type constructor or type alias: int

*)


(*
2011-09-02 ohori

The bug disappears after the fix of 096. Probably the same bug.

*)
