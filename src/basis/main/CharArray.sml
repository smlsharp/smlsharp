(**
 * CharArray
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright 2010, 2011, 2012, 2013 Tohoku University.
 *)

type 'a elem = char

(* object size occupies 26 bits of 32-bit object header. *)
val maxLen = 0x03ffffff

_use "./Array_common.sml"

infix 6 + - ^
infix 4 = <> > >= < <=
val op - = SMLSharp_Builtin.Int.sub_unsafe
val op >= = SMLSharp_Builtin.Int.gteq
structure Array = SMLSharp_Builtin.Array
structure String = SMLSharp_Builtin.String

structure CharArray =
struct
  open Array_common
  type elem = unit elem
  type vector = string
  type array = unit array
  val length = length : array -> int
  val sub = sub : array * int -> elem
  val update = update : array * int * elem -> unit
  val copy = copy : {di:int, dst:array, src:array} -> unit

  (* NOTE:
   * CharVector.vector is not "char vector", but "string".
   * We cannot use the common implementation of vector and copyVec for
   * CharArray.
   *)

  fun vector (ary : array) =
      let
        val len = Array.length ary
        val buf = String.alloc len  (* raise Size if len = 0xffffffff *)
      in
        Array.copy_unsafe (ary, 0, String.castToArray buf, 0, len);
        buf
      end

  fun copyVec {src : vector, dst : array, di} =
      let
        val slen = String.size src
        val dlen = Array.length dst
      in
        if di >= 0 andalso dlen >= di andalso dlen - di >= slen
        then Array.copy_unsafe (String.castToArray src, 0, dst, di, slen)
        else raise Subscript
      end

end
