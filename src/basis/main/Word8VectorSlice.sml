(**
 * Word8VectorSlice
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

type 'a elem = word8

(* object size occupies 26 bits of 32-bit object header. *)
val maxLen = 0x03ffffff

_use "./VectorSlice_common.sml"

structure Word8VectorSlice =
struct
  open VectorSlice_common
  type elem = unit elem
  type vector = unit vector
  type slice = unit slice
end
