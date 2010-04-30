structure STR =
struct
  datatype dt = D | E | F
  val x = E
end;

(* OK *)
signature SIG1 =
sig
  datatype dt = D | E | F
  val x : dt
end;
structure STR1 = STR : SIG1;
val r1 = STR1.x = STR1.E;

(* NG *)
signature SIG2 =
sig
  datatype dt = E | F | D
  val x : dt
end;
structure STR2 = STR : SIG2;
val r2 = STR2.x = STR2.E;

structure STR3 = STR : SIG2;
val r3 = STR3.x = STR3.E;

