(**
 * CharVectorSlice
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

(* NOTE:
 * CharVector.vector is not "char vector", but "string".
 * The only difference between "char vector" and "string" is that a "string"
 * is terminated by a sentinel null character, whereas "char vector" has
 * no sentinel.
 *)

structure Seq =
struct
  type 'a seq = string
  type 'a elem = char
  val castToArray = SMLSharp_Builtin.String.castToArray
  val length = SMLSharp_Builtin.String.size
  val alloc = SMLSharp_Builtin.String.alloc
  val alloc_unsafe = SMLSharp_Builtin.String.alloc_unsafe
  type 'a vector = string
  val castVectorToArray = SMLSharp_Builtin.String.castToArray
  val allocVector = SMLSharp_Builtin.String.alloc
  val allocVector_unsafe = SMLSharp_Builtin.String.alloc_unsafe
  fun emptyVector () = ""
  structure VectorSlice = struct fun base x = x end
end

_use "./Slice_common.sml"

structure CharVectorSlice =
struct
  open Slice_common
  type elem = char
  type vector = string
  type slice = unit slice
end
