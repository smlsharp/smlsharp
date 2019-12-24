(**
 * CharArray
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
  fun empty () = alloc_unsafe 0
  type 'a vector = string
  val castVectorToArray = SMLSharp_Builtin.String.castToArray
  (*
   * Because of the implicit sentinel character, the maximum length of
   * "string" is 1-element shorter than "char array".  To check this
   * difference, allocVector_unsafe must be String.alloc, not alloc_unsafe.
   *)
  val allocVector_unsafe = SMLSharp_Builtin.String.alloc
  val vectorLength = SMLSharp_Builtin.String.size
end

_use "./Array_common.sml"

structure CharArray =
struct
  open Array_common
  type elem = char
  type vector = string
  type array = char array
  val update = SMLSharp_Builtin.Array.update
  (* object size occupies 28 bits of 32-bit object header. *)
  val maxLen = 0x0fffffff
end
