local

  structure UTF8CodecPrimArg = 
  struct

    val names = ["UTF-8"]

    val minOrdw = 0w0 : Word32.word
    val maxOrdw = 0wx10FFFF : Word32.word

    local
      structure V = Vector
      structure VS = VectorSlice
      structure BV = Word8Vector
      structure BVS = Word8VectorSlice

      val W32 = Word32.fromLargeWord o Word8.toLargeWord
      val W8 = Word8.fromLargeWord o Word32.toLargeWord
      val (<<, >>, orb, andb) = (Word32.<<, Word32.>>, Word32.orb, Word32.andb)
      infix << >> orb andb

      fun C1 b1 = W32 b1
      fun C2 (b1, b2) = ((0wx1F andb W32 b1) << 0w6) orb (0wx3F andb W32 b2)
      fun C3 (b1, b2, b3) = 
          ((0wxF andb W32 b1) << 0w12)
              orb ((0wx3F andb W32 b2) << 0w6)
              orb (0wx3F andb W32 b3)
      fun C4 (b1, b2, b3, b4) =
          ((0wx7 andb W32 b1) << 0w18)
              orb ((0wx3F andb W32 b2) << 0w12)
              orb ((0wx3F andb W32 b3) << 0w6)
              orb (0wx3F andb W32 b4)
      fun C5 (b1, b2, b3, b4, b5) =
          ((0wx3 andb W32 b1) << 0w24)
              orb ((0wx3F andb W32 b2) << 0w18)
              orb ((0wx3F andb W32 b3) << 0w12)
              orb ((0wx3F andb W32 b4) << 0w6)
              orb (0wx3F andb W32 b5)
      fun C6 (b1, b2, b3, b4, b5, b6) =
          ((0wx1 andb W32 b1) << 0w30)
              orb ((0wx3F andb W32 b2) << 0w24)
              orb ((0wx3F andb W32 b3) << 0w18)
              orb ((0wx3F andb W32 b4) << 0w12)
              orb ((0wx3F andb W32 b5) << 0w6)
              orb (0wx3F andb W32 b6)
    in

    (*
     * <table>
     * <tr><th>encoded</th><th>codepoint</th><th>codepoint</th></tr>
     * <tr>
     * <td>0xxxxxxx</td>
     * <td>00000000 00000000 00000000 0xxxxxxx</td>
     * <td>U-00000000 - U-0000007F</td>
     * </tr>
     * <tr>
     * <td>110xxxxx 10yyyyyy</td>
     * <td>00000000 00000000 00000xxx xxyyyyyy</td>
     * <td>U-00000080 - U-000007FF</td>
     * </tr>
     * <tr>
     * <td>1110xxxx 10yyyyyy 10zzzzzz</td>
     * <td>00000000 00000000 xxxxyyyy yyzzzzzz</td>
     * <td>U-00000800 - U-0000FFFF</td>
     * </tr>
     * <tr>
     * <td>11110xxx 10yyyyyy 10zzzzzz 10wwwwww</td>
     * <td>00000000 000xxxyy yyyyzzzz zzwwwwww</td>
     * <td>U-00010000 - U-001FFFFF</td>
     * </tr>
     * <tr>
     * <td>111110xx 10yyyyyy 10zzzzzz 10wwwwww 10vvvvvv</td>
     * <td>000000xx yyyyyyzz zzzzwwww wwvvvvvv</td>
     * <td>U-00200000 - U-03FFFFFF</td>
     * </tr>
     * <tr>
     * <td>1111110x 10yyyyyy 10zzzzzz 10wwwwww 10vvvvvv 10uuuuuu</td>
     * <td>0xyyyyyy zzzzzzww wwwwvvvv vvuuuuuu</td>
     * <td>U-04000000 - U-7FFFFFFF</td>
     * </tr>
     * </table>
     *)
    fun decode buffer =
        let
          val bufferLength = BVS.length buffer
          fun nextChar index =
              let
                fun sub offset = BVS.sub (buffer, index + offset)
                val b1 = sub 0
              in
                if b1 <= 0wx7F
                then (C1 b1, 1)
                else
                  if b1 <= 0wxDF
                  then (C2 (b1, sub 1), 2)
                  else
                    if b1 <= 0wxEF
                    then (C3 (b1, sub 1, sub 2), 3)
                    else
                      if b1 <= 0wxF7
                      then (C4 (b1, sub 1, sub 2, sub 3), 4)
                      else
                        if b1 <= 0wxFB
                        then (C5 (b1, sub 1, sub 2, sub 3, sub 4), 5)
                        else
                          if b1 <= 0wxFD
                          then (C6 (b1, sub 1, sub 2, sub 3, sub 4, sub 5), 6)
                          else raise Codecs.BadFormat
              end
          fun scan index codePoints =
              if index < bufferLength
              then
                case nextChar index
                 of (codePoint, numBytes) =>
                    scan (index + numBytes) (codePoint :: codePoints)
              else VS.full(V.fromList(List.rev codePoints))
        in
          scan 0 []
        end

    fun encodeChar word32 =
        List.map
            W8
            (if word32 <= 0wx7F
             then [word32]
             else
               if word32 <= 0wx7FF
               then
                 [
                   0wxC0 orb (word32 >> 0w6),
                   0wx80 orb (word32 andb 0wx3F)
                 ]
               else
                 if word32 <= 0wxFFFF
                 then
                   [
                     0wxE0 orb (word32 >> 0w12),
                     0wx80 orb ((word32 >> 0w6) andb 0wx3F),
                     0wx80 orb (word32 andb 0wx3F)
                   ]
                 else
                   if word32 <= 0wx1FFFFF
                   then
                     [
                       0wxF0 orb (word32 >> 0w18),
                       0wx80 orb ((word32 >> 0w12) andb 0wx3F),
                       0wx80 orb ((word32 >> 0w06) andb 0wx3F),
                       0wx80 orb (word32 andb 0wx3F)
                     ]
                   else
                     if word32 <= 0wx3FFFFFF
                     then
                       [
                         0wxF8 orb (word32 >> 0w24),
                         0wx80 orb ((word32 >> 0w18) andb 0wx3F),
                         0wx80 orb ((word32 >> 0w12) andb 0wx3F),
                         0wx80 orb ((word32 >> 0w06) andb 0wx3F),
                         0wx80 orb (word32 andb 0wx3F)
                       ]
                     else
                       [
                         0wxFC orb (word32 >> 0w30),
                         0wx80 orb ((word32 >> 0w24) andb 0wx3F),
                         0wx80 orb ((word32 >> 0w18) andb 0wx3F),
                         0wx80 orb ((word32 >> 0w12) andb 0wx3F),
                         0wx80 orb ((word32 >> 0w06) andb 0wx3F),
                         0wx80 orb (word32 andb 0wx3F)
                       ])

    fun encode string =
        let
          val bytes = 
              VS.foldr
                  (fn (codePoint, bytess) => encodeChar codePoint :: bytess)
                  []
                  string
        in
          BVS.full(BV.fromList (List.concat bytes))
        end
    
    fun convert targetCodec chars = raise Codecs.ConverterNotFound

    end

  end

in

(**
 * fundamental functions to access UTF-8 encoded characters.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: UTF8Codec.sml,v 1.2.28.1 2010/05/11 07:08:04 kiyoshiy Exp $
 *)
structure UTF8Codec :> CODEC =
          Codec(FixedLengthCharPrimCodecBase(UTF8CodecPrimArg))

end
