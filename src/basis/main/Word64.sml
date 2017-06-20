(**
 * Word64, LargeWord
 * @author SASAKI Tomohiro
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright 2014, Tohoku University.
 *)

structure Word =
struct
  open SMLSharp_Builtin.Word64
  type word = word64
  val wordSize = 64
  val fromWord32X = SMLSharp_Builtin.Word32.toWord64X
  fun fromLarge x = x : word
  fun toWord64 x = x : word
  fun toWord64X x = x : word
  val toLargeInt =
      _import "prim_IntInf_fromWord64"
      : __attribute__((unsafe,pure,fast,gc)) word -> IntInf.int
  val intInf_fromInt64 =
      _import "prim_IntInf_fromInt64"
      : __attribute__((unsafe,pure,fast,gc)) int64 -> IntInf.int
  fun toLargeIntX x = intInf_fromInt64 (toInt64X x)
  val fromLargeInt =
      _import "prim_IntInf_toWord64"
      : __attribute__((pure,fast)) IntInf.int -> word
end

_use "./Word_common.sml"

structure Word64 = Word_common
structure LargeWord = Word64
