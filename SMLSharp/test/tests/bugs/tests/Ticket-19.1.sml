signature SIG = sig type 'a t val x : 'a t val f_t : 'a t -> string end;
structure STR : SIG = struct
  datatype 'a dt = C
  fun f_dt C = "C"
  type 'a t = 'a dt
  val f_t = f_dt
  val x = C
end
val x = STR.x val _ = STR.f_t x;
