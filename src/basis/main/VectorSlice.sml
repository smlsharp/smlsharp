(**
 * VectorSlice
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

structure Seq =
struct
  type 'a seq = 'a vector
  type 'a elem = 'a
  val castToArray = SMLSharp_Builtin.Vector.castToArray
  val length = SMLSharp_Builtin.Vector.length
  val alloc = SMLSharp_Builtin.Vector.alloc
  val alloc_unsafe = SMLSharp_Builtin.Vector.alloc_unsafe
  type 'a vector = 'a vector
  val castVectorToArray = SMLSharp_Builtin.Vector.castToArray
  val allocVector = SMLSharp_Builtin.Vector.alloc
  val allocVector_unsafe = SMLSharp_Builtin.Vector.alloc_unsafe
  fun emptyVector () = allocVector_unsafe 0
  structure VectorSlice = struct fun base x = x end
end

_use "./Slice_common.sml"

structure VectorSlice = Slice_common
