functor MonoVectorBase (B : sig end) =
struct
  fun f () = ()
end;
functor MonoArrayBase (B : sig end) =
struct
  structure Vector = MonoVectorBase(B)
  open Vector
end;
local
  structure Operations = struct end
in
structure UnitArray = MonoArrayBase(Operations)
end;
