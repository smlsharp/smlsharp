_interface "134_functor2.smi"
functor F (
  A : sig
    type t2    (* the order of types is different from the interface. *)
    type t1
    val x1 : t1
    val x2 : t2
  end
) =
struct
  fun f () = (A.x1,A.x2)
end
