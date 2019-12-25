(**
 * CharArraySlice
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright 2010, 2011, 2012, 2013 Tohoku University.
 *)

structure Seq =
struct
  type 'a seq = char array
  type 'a elem = char
  fun castToArray x = x
  val length = SMLSharp_Builtin.Array.length
  val alloc = SMLSharp_Builtin.Array.alloc
  val alloc_unsafe = SMLSharp_Builtin.Array.alloc_unsafe
  type 'a vector = string
  val castVectorToArray = SMLSharp_Builtin.String.castToArray
  val allocVector = SMLSharp_Builtin.String.alloc
  (*
   * Because of the implicit sentinel character, the maximum length of
   * "string" is 1-element shorter than "char array".  To check this
   * difference, allocVector_unsafe must be String.alloc, not alloc_unsafe.
   *)
  val allocVector_unsafe = SMLSharp_Builtin.String.alloc
  fun emptyVector () = ""
  structure VectorSlice = CharVectorSlice
end

_use "./Slice_common.sml"

structure CharArraySlice =
struct
  open Slice_common
  type elem = char
  type array = char array
  type vector = string
  type slice = unit slice
  type vector_slice = CharVectorSlice.slice
end
