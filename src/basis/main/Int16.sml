(**
 * Int16
 * @author UENO Katsuhiro
 * @copyright (C) 2021 SML# Development Team.
 *)

structure Int =
struct
  open SMLSharp_Builtin.Int16
  type int = int16
  val precision = 16
  val minInt = ~0x8000 : int
  val maxInt = 0x7fff : int
  fun toLarge x = IntInf.fromInt (toInt32 x)
  fun fromLarge x = fromInt32 (IntInf.toInt x)
end

_use "Int_common.sml"

structure Int16 = Int_common
