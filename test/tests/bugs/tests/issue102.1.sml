signature S = sig eqtype t end;

structure SEqRefTrans : S =
struct
  type t = (real ref * real) ref
end;

structure SEqRefOpaque :> S =
struct
  type t = (real ref * real) ref
end;
