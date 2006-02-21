abstype t2 = D of string
with
  datatype t2 = E of real        (* re-bind t2. *)
  val ax2 : t2 = E 1.23
end;
val gx2 : t2 = ax2;
