structure X : sig
  type t
  val D : t
end = struct
  datatype dt = D
  type t = dt
end
val y = X.D;
