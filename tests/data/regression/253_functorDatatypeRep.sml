functor F(A:sig datatype foo = A end) =
struct
  structure B = A
end
(* 2013-3-21 ohori.
 In 4900:9724260904d7, this causes an unexpected name error.

253_functorDatatypeRep.smi:1.8-7.2 Error:
  (name evaluation CP-720) Provide check fails (functor body signature
  mismatch): F

2013-3-21 ohori.
*)
