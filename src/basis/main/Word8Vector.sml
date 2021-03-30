(**
 * Word8Vector
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright (C) 2021 SML# Development Team.
 *)

structure Seq =
struct
  type 'a seq = word8 vector
  type 'a elem = word8
  val castToArray = SMLSharp_Builtin.Vector.castToArray
  val length = SMLSharp_Builtin.Vector.length
  val alloc = SMLSharp_Builtin.Vector.alloc
  val alloc_unsafe = SMLSharp_Builtin.Vector.alloc_unsafe
  fun empty () = alloc_unsafe 0
  type 'a vector = word8 vector
  val castVectorToArray = SMLSharp_Builtin.Vector.castToArray
  val allocVector_unsafe = SMLSharp_Builtin.Vector.alloc_unsafe
  val vectorLength = SMLSharp_Builtin.Vector.length
end

_use "./Array_common.sml"

structure Word8Vector =
struct
  open Array_common
  type elem = word8
  type vector = word8 vector
  val sub = SMLSharp_Builtin.Vector.sub
  (* object size occupies 28 bits of 32-bit object header. *)
  val maxLen = 0x0fffffff
end
