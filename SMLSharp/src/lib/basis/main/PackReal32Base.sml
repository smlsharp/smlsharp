(**
 * packing real value in little-endian byte order.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: PackReal32Base.sml,v 1.1 2007/11/01 01:53:04 kiyoshiy Exp $
 *)
functor PackReal32Base
            (B :
             sig
               val isBigEndian : bool
               val pack : Word8.word * Word8.word * Word8.word * Word8.word
                          -> Real32.real
               val unpack : Real32.real ->
                            Word8.word * Word8.word * Word8.word * Word8.word
             end) : PACK_REAL = 
struct

  structure V = Word8Vector
  structure A = Word8Array

  type real = Real32.real

  val bytesPerElem = 4
  val isBigEndian = B.isBigEndian

  fun toBytes real =
      let
        val (b0, b1, b2, b3) = B.unpack real
      in
        V.fromList [b0, b1, b2, b3]
      end

  local
    fun pack sub i v =
        B.pack
            (sub(v, i + 0), sub(v, i + 1), sub(v, i + 2), sub(v, i + 3))
  in
  fun fromBytes vector = pack V.sub 0 vector
  fun subVec (vector, i) = pack V.sub i vector
  fun subArr (array, i) = pack A.sub i array
  end

  fun update (array, i, real) =
      let
        val (b0, b1, b2, b3) = B.unpack real
      in
        A.update (array, i + 0, b0);
        A.update (array, i + 1, b1);
        A.update (array, i + 2, b2);
        A.update (array, i + 3, b3)
      end

end
