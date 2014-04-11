(**
 * Word8Array
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 * @copyright 2010, 2011, 2012, 2013 Tohoku University.
 *)

type 'a elem = SMLSharp_Builtin.Word8.word

(* object size occupies 26 bits of 32-bit object header. *)
val maxLen = 0x03ffffff

_use "./Array_common.sml"

structure Word8Array =
struct
  open Array_common
  type elem = unit elem
  type vector = unit vector
  type array = unit array
  val length = length : array -> int
  val sub = sub : array * int -> elem
  val update = update : array * int * elem -> unit
  val copy = copy : {di:int, dst:array, src:array} -> unit
end
