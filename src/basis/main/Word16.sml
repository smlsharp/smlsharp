(**
 * Word16
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright (C) 2021 SML# Development Team.
 *)

structure Word =
struct
  open SMLSharp_Builtin.Word16
  type word = word16
  val wordSize = 16
  val fromWord32X = SMLSharp_Builtin.Word32.toWord16
  val fromLarge = SMLSharp_Builtin.Word64.toWord16
  val toLargeInt32 =
      _import "prim_IntInf_fromWord"
      : __attribute__((unsafe,pure,fast,gc))
        word32 -> IntInf.int
  fun toLargeInt x = toLargeInt32 (toWord32 x)
  fun toLargeIntX x = IntInf.fromInt (toInt32X x)
  val fromLargeInt32 =
      _import "prim_IntInf_toWord"
      : __attribute__((unsafe,pure,fast)) IntInf.int -> word32
  fun fromLargeInt x = fromWord32X (fromLargeInt32 x)
end

_use "./Word_common.sml"

structure Word16 = Word_common
