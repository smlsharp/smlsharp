(**
 * CharArraySlice
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright 2010, 2011, 2012, 2013 Tohoku University.
 *)

type 'a elem = char

(* object size occupies 26 bits of 32-bit object header. *)
val maxLen = 0x03ffffff

structure VectorSlice =
struct
  exception Dummy
  fun base (x : CharVectorSlice.slice) =
      ((raise Dummy) : char vector, 0, 0)  (* dummy *)
end

_use "./ArraySlice_common.sml"

infix 6 + - ^
infix 4 = <> > >= < <=
val op - = SMLSharp_Builtin.Int.sub_unsafe
val op >= = SMLSharp_Builtin.Int.gteq
structure Array = SMLSharp_Builtin.Array
structure String = SMLSharp_Builtin.String

structure CharArraySlice =
struct
  open ArraySlice_common
  type elem = char
  type vector = string
  type array = unit array
  type slice = unit slice
  type vector_slice = CharVectorSlice.slice

  (* NOTE:
   * CharVector.vector is not "char vector", but "string".
   * We cannot use the common implementation of vector and copyVec for
   * CharArray.
   *)

  fun vector ((ary, start, length) : slice) =
      let
        val buf = String.alloc length  (* raise Size if len = 0xffffffff *)
      in
        Array.copy_unsafe (ary, start, String.castToArray buf, 0, length);
        buf
      end

  fun copyVec {src : vector_slice, dst : array, di} =
      let
        val (vec, start, length) = CharVectorSlice.base src
        val dlen = Array.length dst
      in
        if di >= 0 andalso dlen >= di andalso dlen - di >= length
        then Array.copy_unsafe (String.castToArray vec, start, dst, di, length)
        else raise Subscript
      end

end
