functor F(P:sig type foo val y : foo end) = 
   struct 
     abstype bar = A of P.foo
     with
       val z = A
       val x = A P.y
     end
   end
functor G(Q:sig type foo val y : foo end) = struct structure C = F(Q) end

(* 2012-7-31 ohori
   This cases a bug exception:
   [BUG] EvalITy: free tvar:'foo(tv31)   
*)
(* 2012-8-1 ohori
   Fixed.
*)
