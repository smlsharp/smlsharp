(**
 * Array structure.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @author Atsushi Ohori (refactored)
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

type 'a elem = 'a

(* object size occupies 26 bits of 32-bit object header,
 * and the size of the maximum value is 8 bytes.
 * so we take 2^23 for maxLen. *)
val maxLen = 0x007fffff

_use "./Array_common.sml"

structure Array = Array_common
