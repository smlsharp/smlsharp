signature A =
 sig
   structure A : sig type foo end
   structure B : sig type bar end
   sharing type A.foo = B.bar
 end
functor F(P:A) = struct end

(* 2012-7-29 ohori
  Provide signature does not have sharing constraint but 
  this is accepted.
*)
(* 2012-8-1 ohori
  Fixed.
*)
