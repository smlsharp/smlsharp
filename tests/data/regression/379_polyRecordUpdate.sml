fun f x y =  x # {a = y};
val r = f {a = 1} 2;

(*
This yields an incorrect result:
  # fun f x y =  x # {a = y};
  val f = fn : ['a#{a: 'b}, 'b. 'a -> 'b -> 'a]
  # val r = f {a = 1} 2;
  val r = {a = ~1051407120} : {a: int} (* val r = {a = 2} is expected *)
*)
