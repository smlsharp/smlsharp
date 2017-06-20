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
  val Word32_toWordN = SMLSharp_Builtin.Word32.toWord8
  val WordN_toIntNX = SMLSharp_Builtin.Word8.toInt8X
  fun toLarge x = IntInf.fromInt (toInt32 x)
  fun fromLarge x =
      let val x = IntInf.toInt x
      in if SMLSharp_Builtin.Int32.lt (x, toInt32 minInt)
            orelse SMLSharp_Builtin.Int32.lt (toInt32 maxInt, x)
         then raise Overflow
         else WordN_toIntNX
                (Word32_toWordN (SMLSharp_Builtin.Word32.fromInt32 x))
      end
end

_use "Int_common.sml"

structure Int8 = Int_common
