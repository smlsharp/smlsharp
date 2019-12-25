(**
 * Array structure.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @author Atsushi Ohori (refactored)
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

structure Seq =
struct
  type 'a seq = 'a array
  type 'a elem = 'a
  fun castToArray x = x
  val length = SMLSharp_Builtin.Array.length
  val alloc = SMLSharp_Builtin.Array.alloc
  val alloc_unsafe = SMLSharp_Builtin.Array.alloc_unsafe
  fun empty () = alloc_unsafe 0
  type 'a vector = 'a vector
  val castVectorToArray = SMLSharp_Builtin.Vector.castToArray
  val allocVector_unsafe = SMLSharp_Builtin.Vector.alloc_unsafe
  val vectorLength = SMLSharp_Builtin.Vector.length
end

_use "./Array_common.sml"

structure Array =
struct
  open Array_common
  type 'a array = 'a array
  type 'a vector = 'a vector
  val update = SMLSharp_Builtin.Array.update
  (* object size occupies 28 bits of 32-bit object header.
   * Actual maximum size depends on the element size. *)
  val maxLen = 0x0fffffff
end
