_interface "099_provide.smi"

structure S :> sig
  eqtype t
  val f : 'a -> 'a -> t
end =
struct
  type t = unit
  fun f x y = ()
end

(*
2011-09-02 katsu

This causes an unexpected type error.

099_provide.smi:4.7-4.23 Error:
  (type inference 063) type and type annotation don't agree
    inferred type: 'F('RIGID(tv35)) -> 'F('RIGID(tv35)) -> unit(t7[])
  type annotation: 'F('RIGID(tv35))
                   -> 'F('RIGID(tv35)) -> t(t31[[opaque(rv1,t(t7[]))]])
*)


(*
2011-09-03 ohori

Fixed.
InferTypes sometimes reconstruct polytype in generalizeInNotThere 
resulting in losing the opaque annotation.

*)
