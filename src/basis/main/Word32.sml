(**
 * Word, Word32
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright (C) 2021 SML# Development Team.
 *)

structure Word =
struct
  open SMLSharp_Builtin.Word32
  type word = word
  val wordSize = 32
  fun fromWord32X x = x : word
  fun toWord32 x = x : word
  val fromLarge = SMLSharp_Builtin.Word64.toWord32
  val toLargeInt =
      _import "prim_IntInf_fromWord"
      : __attribute__((unsafe,pure,fast,gc))
        word -> IntInf.int
  fun toLargeIntX x = IntInf.fromInt (toInt32X x)
  val fromLargeInt =
      _import "prim_IntInf_toWord"
      : __attribute__((unsafe,pure,fast)) IntInf.int -> word
end

_use "./Word_common.sml"

structure Word32 = Word_common
structure Word = Word32
