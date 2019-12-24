(**
 * Int8
 * @author UENO Katsuhiro
 * @copyright 2016, Tohoku University.
 *)

structure Int =
struct
  open SMLSharp_Builtin.Int8
  type int = int8
  val precision = 8
  val minInt = ~0x80 : int
  val maxInt = 0x7f : int
  fun toLarge x = IntInf.fromInt (toInt32 x)
  fun fromLarge x = fromInt32 (IntInf.toInt x)
end

_use "Int_common.sml"

structure Int8 = Int_common
