_interface "108_functordty.smi"
structure S = F()

(*
2011-09-04 katsu

This causes an unexpected name error.

108_functordty.smi:4.21-4.21 Error:
  (name evaluation Ty-040) unbound type constructor or type alias: s
108_functordty.smi:5.16-5.16 Error:
  (name evaluation Ty-040) unbound type constructor or type alias: t
*)


(*
2011-09-05 ohori

Fixed by rewriting checkDatabindList in CheckProvide.
The code needs some clean up.

*)
