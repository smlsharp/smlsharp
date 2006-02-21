signature SType = sig type t val x : t end;
structure SType = struct type t = int val x = 1 end;
structure STypeOpaque1 = SType :> SType;
structure STypeOpaque2 = SType :> SType;
val eqSTypeOpaque = STypeOpaque1.x = STypeOpaque2.x;
