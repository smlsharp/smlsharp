(**
 * CharVector
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
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
  fun empty () = ""
  type 'a vector = string
  val castVectorToArray = SMLSharp_Builtin.String.castToArray
  val allocVector_unsafe = SMLSharp_Builtin.String.alloc_unsafe
  val vectorLength = SMLSharp_Builtin.String.size
end

_use "./Array_common.sml"

structure CharVector =
struct
  open Array_common
  type elem = char
  type vector = string
  val sub = SMLSharp_Builtin.String.sub
  (* object size occupies 28 bits of 32-bit object header.
   * "string" have a sentinel null character at the end of the sequence *)
  val maxLen = 0x0ffffffe
end
