_interface "121_functor.smi"
(* 121_functor2.smi
  structure S =
    struct
     val f : int -> int
   end
*)
functor F () =
struct
  structure T = S
end
structure A = F()
val x = A.T.f

(*
2011-09-06 katsu

EXTERNVAR and EXVAR are mismatched.

extern var S.f : int(t0[]) -> int(t0[])
val _.F(1) : unit(t7[]) -> {1: int(t0[]) -> int(t0[])} =
 (fn unitVar(0) : unit(t7[]) =>
  let
   
  in
   (T.f)   (****** <=== this should be S.f *******)
    :{1: int(t0[]) -> int(t0[])} : {{1: int(t0[]) -> int(t0[])}}
  end
  :{1: int(t0[]) -> int(t0[])})
*)

(*
2011-09-06 ohori

This is due to the difference between the path to be bound in the envivonment
and the external name path. 

Some cheking code added.
*)
