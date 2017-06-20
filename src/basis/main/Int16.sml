(**
 * Int16
 * @author UENO Katsuhiro
 * @copyright 2016, Tohoku University.
 *)

structure Int =
struct
  open SMLSharp_Builtin.Int16
  type int = int16
  val precision = 16
  val minInt = ~0x8000 : int
  val maxInt = 0x7fff : int
  val Word32_toWordN = SMLSharp_Builtin.Word32.toWord16
  val WordN_toIntNX = SMLSharp_Builtin.Word16.toInt16X
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

structure Int16 = Int_common
