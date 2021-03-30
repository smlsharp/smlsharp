(**
 * Word8VectorSlice
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
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
  type 'a vector = word8 vector
  val castVectorToArray = SMLSharp_Builtin.Vector.castToArray
  val allocVector = SMLSharp_Builtin.Vector.alloc
  val allocVector_unsafe = SMLSharp_Builtin.Vector.alloc_unsafe
  fun emptyVector () = allocVector_unsafe 0
  structure VectorSlice = struct fun base x = x end
end

_use "./Slice_common.sml"

structure Word8VectorSlice =
struct
  open Slice_common
  type elem = word8
  type vector = word8 vector
  type slice = unit slice
end
