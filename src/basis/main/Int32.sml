(**
 * Int, Int32, Position
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

structure Int =
struct
  open SMLSharp_Builtin.Int32
  type int = int
  val precision = 32
  val minInt = ~0x80000000 : int
  val maxInt = 0x7fffffff : int
  fun toInt32 x = x : int
  fun fromInt32 x = x : int
  val toLarge = IntInf.fromInt
  val fromLarge = IntInf.toInt
  fun Word32_toWordN x = x : word
  val WordN_toIntNX = SMLSharp_Builtin.Word32.toInt32X
end

_use "Int_common.sml"

structure Int32 = Int_common
structure Position = Int32
structure Int = Int32
