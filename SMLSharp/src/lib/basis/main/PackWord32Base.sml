(**
 * base functor of PackWord32XXX structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PackWord32Base.sml,v 1.1 2007/03/08 08:07:00 kiyoshiy Exp $
 *)
functor PackWord32Base
            (B :
             sig
               val isBigEndian : bool
               val pack : Word8.word * Word8.word * Word8.word * Word8.word
                          -> Word32.word
               val unpack : Word32.word
                            -> Word8.word * Word8.word * Word8.word * Word8.word
             end) : PACK_WORD = 
struct

  structure V = Word8Vector
  structure A = Word8Array

  val bytesPerElem = Word32.wordSize div 8

  val isBigEndian = B.isBigEndian

  fun subVec (v, i) =
      B.pack
          (V.sub(v, i), V.sub(v, i + 1), V.sub(v, i + 2), V.sub(v, i + 3))
  val subVecX = subVec
  fun subArr (v, i) =
      B.pack
          (A.sub(v, i), A.sub(v, i + 1), A.sub(v, i + 2), A.sub(v, i + 3))
  val subArrX = subArr

  fun update (array, i, word) =
      let
        val (b0, b1, b2, b3) = B.unpack word
      in
        A.update (array, i + 0, b0);
        A.update (array, i + 1, b1);
        A.update (array, i + 2, b2);
        A.update (array, i + 3, b3)
      end

end;

