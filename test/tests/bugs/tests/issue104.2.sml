signature S = sig exception E of int end;
structure SVal1Trans : S =
struct
  exception F
  val E = fn (x : int) => F
end;
