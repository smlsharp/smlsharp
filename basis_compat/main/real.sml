functor RealFn (Orig : Orig_REAL) : REAL =
struct
  open Orig
  val fromLargeInt = fn x => Orig.fromLargeInt (Orig_Int32.toLarge x)
  val toLargeInt = fn m => fn x => Orig_Int32.fromLarge (Orig.toLargeInt m x)
end

structure Real = RealFn(Orig_Real)
structure Real64 = RealFn(Orig_Real64)
