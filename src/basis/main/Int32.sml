(**
 * Int, Int32, Position
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright (C) 2021 SML# Development Team.
 *)

structure Int =
struct
  open SMLSharp_Builtin.Int32
  type int = int32
  val precision = 32
  val minInt = ~0x80000000 : int
  val maxInt = 0x7fffffff : int
  val toLarge = IntInf.fromInt
  val fromLarge = IntInf.toInt
  fun fromInt32 x = x : int
  fun toInt32 x = x : int
end

_use "Int_common.sml"

structure Int32 = Int_common
structure Position = Int32
structure Int = Int32
