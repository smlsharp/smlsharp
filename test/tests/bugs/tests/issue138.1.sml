signature S1 = 
sig
  structure S : sig type t datatype dt = D of t val x : dt end
end;

signature S2 =
sig
  type s
  include sig type t datatype dt = D of t val x : s * t * dt end
  val y : dt * t 
end;

signature S31 =
sig 
  type t
  datatype dt = D of t
  val x : t * dt 
end;
