(**
 * Word8ArraySlice
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
  type 'a vector = word8 vector
  val castVectorToArray = SMLSharp_Builtin.Vector.castToArray
  val allocVector = SMLSharp_Builtin.Vector.alloc
  val allocVector_unsafe = SMLSharp_Builtin.Vector.alloc_unsafe
  fun emptyVector () = allocVector_unsafe 0
  structure VectorSlice = Word8VectorSlice
end

_use "./Slice_common.sml"

structure Word8ArraySlice =
struct
  open Slice_common
  type elem = word8
  type array = word8 array
  type vector = word8 vector
  type slice = unit slice
  type vector_slice = Word8VectorSlice.slice
end
