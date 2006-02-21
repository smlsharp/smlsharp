signature SType = 
sig
  type t
  val x : t
end;
structure PType = struct type t = real val x = 1.23 end;

functor FTypeOpaque(S : sig type t val x : t end) = 
struct type t = int datatype t = D of S.t val x = D(S.x) end 
:> SType;

structure STypeOpaque = FTypeOpaque(PType);
