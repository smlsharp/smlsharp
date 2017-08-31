functor F(A:sig end) =
struct
  exception Foo = FOO
  exception Bar = BAR
  structure S = ST
end

(* 2012-10-1 ohori
This causes unexpected name error
242_functorExn.smi:2.9-7.3 Error:
  (name evaluation CP-720) Provide check fails (functor body signature
  mismatch): F
*)
(* 2012-10-1 ohori
  Fixed. exception representation processing was missing 
  for interface.
*)
