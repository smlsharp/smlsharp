(**
 * Word8Vector
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

type 'a elem = SMLSharp_Builtin.Word8.word

(* object size occupies 26 bits of 32-bit object header. *)
val maxLen = 0x03ffffff

_use "./Vector_common.sml"

structure Word8Vector =
struct
  open Vector_common
  type elem = unit elem
  type vector = unit vector
  val length = length : vector -> int
  val sub = sub : vector * int -> elem
end
