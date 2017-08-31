_interface "137_functor.smi"
val x = S.x

(*
2011-09-09 katsu

This causes link error due to difference of external names.
137_functor2.sml exports "F.x", but 137_functor.sml imports "S.x".

after InferTypes:

137_functor2.sml:
export variable F.x(0) : int(t0[])

137_functor.sml:
extern var S.x : int(t0[])

*)

(*
2011-09-10 ohori

Fixed. 
*)
