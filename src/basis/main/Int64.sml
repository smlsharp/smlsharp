(**
 * Int64
 * @author SASAKI Tomohiro
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright 2014, Tohoku University.
 *)

structure Int =
struct
  open SMLSharp_Builtin.Int64
  type int = int64
  val precision = 64
  val minInt = ~0x8000000000000000 : int
  val maxInt = 0x7fffffffffffffff : int
  val Word32_toWordN = SMLSharp_Builtin.Word32.toWord64
  val WordN_toIntNX = SMLSharp_Builtin.Word64.toInt64X
  val toLarge =
      _import "prim_IntInf_fromInt64"
      : __attribute__((unsafe,pure,fast,gc)) int -> intInf
  val Word64_fromLarge =
      _import "prim_IntInf_toWord64"
      : __attribute__((pure,fast)) IntInf.int -> word64
  fun fromLarge x =
      if IntInf.< (x, toLarge minInt) orelse IntInf.< (toLarge maxInt, x)
      then raise Overflow
      else WordN_toIntNX (Word64_fromLarge x)
end

_use "Int_common.sml"

structure Int64 = Int_common
