(**
 * Vector
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright (C) 2021 SML# Development Team.
 *)

structure Seq =
struct
  type 'a seq = 'a vector
  type 'a elem = 'a
  val castToArray = SMLSharp_Builtin.Vector.castToArray
  val length = SMLSharp_Builtin.Vector.length
  val alloc = SMLSharp_Builtin.Vector.alloc
  val alloc_unsafe = SMLSharp_Builtin.Vector.alloc_unsafe
  fun empty () = alloc_unsafe 0
  type 'a vector = 'a vector
  val castVectorToArray = SMLSharp_Builtin.Vector.castToArray
  val allocVector_unsafe = SMLSharp_Builtin.Vector.alloc_unsafe
  val vectorLength = SMLSharp_Builtin.Vector.length
end

_use "./Array_common.sml"

structure Vector =
struct
  open Array_common
  type 'a vector = 'a vector
  val sub = SMLSharp_Builtin.Vector.sub
  (* object size occupies 28 bits of 32-bit object header.
   * Actual maximum size depends on the element size. *)
  val maxLen = 0x0fffffff
end
