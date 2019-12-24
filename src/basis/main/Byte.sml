(**
 * Byte
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

infix 7 * / div mod
infix 6 + -
infixr 5 ::
infix 4 = <> > >= < <=
val op + = SMLSharp_Builtin.Int32.add_unsafe
val op - = SMLSharp_Builtin.Int32.sub_unsafe
val op > = SMLSharp_Builtin.Int32.gt
val op < = SMLSharp_Builtin.Int32.lt
val op <= = SMLSharp_Builtin.Int32.lteq
val op >= = SMLSharp_Builtin.Int32.gteq
structure Array = SMLSharp_Builtin.Array
structure Vector = SMLSharp_Builtin.Vector
structure String = SMLSharp_Builtin.String

structure Byte =
struct

  val byteToChar = SMLSharp_Builtin.Word8.castToChar
  val charToByte = SMLSharp_Builtin.Char.castToWord8

  fun bytesToString vec =
      let
        val len = Vector.length vec
        val buf = String.alloc len
      in
        Array.copy_unsafe (Vector.castToArray vec, 0,
                           String.castToWord8Array buf, 0, len);
        buf
      end

  fun stringToBytes vec =
      let
        val len = String.size vec
        val buf = Vector.alloc_unsafe len
      in
        Array.copy_unsafe (String.castToWord8Array vec, 0,
                           Vector.castToArray buf, 0, len);
        buf
      end

  fun unpackStringVec slice =
      let
        val (vec, start, length) = Word8VectorSlice.base slice
        val buf = String.alloc length
      in
        Array.copy_unsafe (Vector.castToArray vec, start,
                           String.castToWord8Array buf, 0, length);
        buf
      end

  fun unpackString slice =
      let
        val (ary, start, length) = Word8ArraySlice.base slice
        val buf = String.alloc length
      in
        Array.copy_unsafe (ary, start, String.castToWord8Array buf, 0, length);
        buf
      end

  fun packString (dst, di, src) =
      let
        val (vec, start, length) = Substring.base src
        val dlen = Array.length dst
      in
        if di >= 0 andalso dlen >= di andalso dlen - di >= length
        then Array.copy_unsafe (String.castToWord8Array vec, start,
                                dst, di, length)
        else raise Subscript
      end

end
