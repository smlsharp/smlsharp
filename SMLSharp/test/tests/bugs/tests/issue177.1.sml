fun get (SOME v) = v;
functor MonoVectorBase (B : sig end) =
struct
  fun concat vector = get vector
end;
functor MonoArrayBase (B : sig end) =
struct
  structure Vector = MonoVectorBase(B)
end;
structure UnitArray = MonoArrayBase(struct end);
