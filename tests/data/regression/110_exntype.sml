_interface "110_exntype.smi"

structure S
 :> sig
  type t
  val x : t
  exception E of t
end
 =
struct
  type t = int
  val x = 1
  exception E of int
end

(*
2011-09-05 katsu

This causes an unexpected name error.

110_exntype.smi:4.13-4.18 Error:
  (name evaluation CP-270) Provide check fails (exception type mistch) : S.E
*)
