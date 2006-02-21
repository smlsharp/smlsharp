functor F(P : sig type dt val x : dt val fmt : dt -> string end) =
struct
  datatype dt = F of P.dt 
  val x = F(P.x) 
  fun fmt (F x) = P.fmt x 
end;
structure P = struct datatype dt = D val x = D fun fmt D = "D" end;
structure T2 = F(F(P));
val x2 = T2.x;
T2.fmt x2;
