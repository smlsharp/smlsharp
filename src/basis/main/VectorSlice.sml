(**
 * VectorSlice
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

type 'a elem = 'a

(* object size occupies 26 bits of 32-bit object header,
 * and the size of the maximum value is 8 bytes.
 * so we take 2^23 for maxLen. *)
val maxLen = 0x007fffff

_use "./VectorSlice_common.sml"

structure VectorSlice = VectorSlice_common
