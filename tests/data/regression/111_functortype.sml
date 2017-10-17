_interface "111_functortype.smi"
functor F () =
struct
  type t = int
end
structure S = F ()

(*
2011-09-05 katsu

This causes an unexpected name error.
I guess that this is due to same reason as 108_functordty.

111_functortype.smi:3.8-3.14 Error:
  (name evaluation CP-190) Provide check fails (type definition) : S.t

*)


(*
2011-09-05 ohori

This is the same bug as 110 (int is incorrectly refreshed
by some new type) and has been taken care of.
*)
