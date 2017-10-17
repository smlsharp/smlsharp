_interface "123_functor.smi"
functor F (
  A : sig
   type t
  end
) =
struct
  val x = 1
end

(*
2011-09-06 katsu

funtor "F" is not exported.

After InferTypes:

val _.F(2) : ['a. ({1: 'a} -> {1: 'a}) -> {1: int(t0[])}] =
 ['b.
  fn {id(0) : {1: 'a} -> {1: 'a}} =>
    let
      val x(1) : int(t0[]) = 1 : int(t0[])
    in
      (x(1) : int(t0[])) :{1: int(t0[])} : {{1: int(t0[])}}
    end
    :{1: int(t0[])}
 ]
(***** "_.F" must be exported here. *****)

*)

(*
2011-09-06 ohori

Fixed the two bugs:
(1) not registering the sig equality check error 
(2) missing case in TFV_SPEC in equalTfun

*)
