(**
 * ArraySlice
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
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
  type 'a vector = 'a vector
  val castVectorToArray = SMLSharp_Builtin.Vector.castToArray
  val allocVector = SMLSharp_Builtin.Vector.alloc
  val allocVector_unsafe = SMLSharp_Builtin.Vector.alloc_unsafe
  fun emptyVector () = allocVector_unsafe 0
  structure VectorSlice = VectorSlice
end

_use "./Slice_common.sml"

structure ArraySlice = Slice_common
