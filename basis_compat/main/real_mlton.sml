functor RealFn (Orig : Orig_REAL) : REAL =
struct
  open Orig
  val fromLargeInt = fn x => Orig.fromLargeInt (Orig_Int32.toLarge x)
  val toLargeInt = fn m => fn x => Orig_Int32.fromLarge (Orig.toLargeInt m x)
  val fromDecimal =
      fn a => case Orig.fromDecimal a of NONE => Orig.fromInt 0 | SOME r => r
end

structure Real = RealFn(Orig_Real)
structure Real64 = RealFn(Orig_Real64)
