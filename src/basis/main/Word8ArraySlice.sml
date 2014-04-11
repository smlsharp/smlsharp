(**
 * Word8ArraySlice
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 * @copyright 2010, 2011, 2012, 2013 Tohoku University.
 *)

type 'a elem = SMLSharp_Builtin.Word8.word

(* object size occupies 26 bits of 32-bit object header. *)
val maxLen = 0x03ffffff

structure VectorSlice = Word8VectorSlice

_use "./ArraySlice_common.sml"

structure Word8ArraySlice =
struct
  open ArraySlice_common
  type elem = unit elem
  type array = unit array
  type vector = unit vector
  type slice = unit slice
  type vector_slice = VectorSlice.slice
end
