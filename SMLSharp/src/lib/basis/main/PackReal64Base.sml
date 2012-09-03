(**
 * packing real value in little-endian byte order.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PackReal64Base.sml,v 1.1 2007/03/08 08:07:00 kiyoshiy Exp $
 *)
functor PackReal64Base
            (B :
             sig
               val isBigEndian : bool
               val pack
                   : Word8.word * Word8.word * Word8.word * Word8.word
                     * Word8.word * Word8.word * Word8.word * Word8.word
                     -> Real64.real
               val unpack
                   : Real64.real
                     -> Word8.word * Word8.word * Word8.word * Word8.word
                        * Word8.word * Word8.word * Word8.word * Word8.word
             end) : PACK_REAL = 
struct

  structure V = Word8Vector
  structure A = Word8Array

  type real = Real64.real

  val bytesPerElem = 8
  val isBigEndian = B.isBigEndian

  fun toBytes real =
      let
        val (b0, b1, b2, b3, b4, b5, b6, b7) = B.unpack real
      in
        V.fromList [b0, b1, b2, b3, b4, b5, b6, b7]
      end

  local
    fun pack sub i v =
        B.pack
            (sub(v, i + 0), sub(v, i + 1), sub(v, i + 2), sub(v, i + 3), 
             sub(v, i + 4), sub(v, i + 5), sub(v, i + 6), sub(v, i + 7))
  in
  fun fromBytes vector = pack V.sub 0 vector
  fun subVec (vector, i) = pack V.sub i vector
  fun subArr (array, i) = pack A.sub i array
  end

  fun update (array, i, real) =
      let
        val (b0, b1, b2, b3, b4, b5, b6, b7) = B.unpack real
      in
        A.update (array, i + 0, b0);
        A.update (array, i + 1, b1);
        A.update (array, i + 2, b2);
        A.update (array, i + 3, b3);
        A.update (array, i + 4, b4);
        A.update (array, i + 5, b5);
        A.update (array, i + 6, b6);
        A.update (array, i + 7, b7)
      end

end
