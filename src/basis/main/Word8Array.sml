(**
 * Word8Array
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 * @copyright (C) 2021 SML# Development Team.
 *)

structure Seq =
struct
  type 'a seq = word8 array
  type 'a elem = word8
  fun castToArray x = x
  val length = SMLSharp_Builtin.Array.length
  val alloc = SMLSharp_Builtin.Array.alloc
  val alloc_unsafe = SMLSharp_Builtin.Array.alloc_unsafe
  fun empty () = alloc_unsafe 0
  type 'a vector = word8 vector
  val castVectorToArray = SMLSharp_Builtin.Vector.castToArray
  val allocVector_unsafe = SMLSharp_Builtin.Vector.alloc_unsafe
  val vectorLength = SMLSharp_Builtin.Vector.length
end

_use "./Array_common.sml"

structure Word8Array =
struct
  open Array_common
  type elem = word8
  type vector = word8 vector
  type array = word8 array
  val update = SMLSharp_Builtin.Array.update
  (* object size occupies 28 bits of 32-bit object header. *)
  val maxLen = 0x0fffffff
end
