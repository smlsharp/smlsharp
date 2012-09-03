(**
 * Utilities to convert data types.
 * @copyright (c) 2010, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: OLE.sml,v 1.27.22.2 2010/05/09 03:58:29 kiyoshiy Exp $
 *)
structure OLE_DataConverter =
struct

  (****************************************)

  structure Int8 = Int32 (* FIXME : We should have Int8. *)
  structure Int16 = Int32
  structure Word16 = Word32

  structure E = OLE_Error

  (****************************************)

  val int32ToWord32 = Word32.fromLargeInt o Int32.toLarge
  val word32ToInt32 = Int32.fromLarge o Word32.toLargeInt
  val word32ToInt32X = Int32.fromLarge o Word32.toLargeIntX

  val word32ToIntInf = IntInf.fromLarge o Word32.toLargeInt
  val word32ToIntInfX = IntInf.fromLarge o Word32.toLargeIntX

  local
    val MaxWord8 = 0wxFF : Word32.word
  in
  val word8ToWord32 = Word32.fromLarge o Word8.toLarge
  fun word32ToWord8 word32 =
      if (MaxWord8 < word32)
      then raise E.OLEError (E.Conversion "cannot convert Word8 to Word32.")
      else (Word8.fromLarge o Word32.toLarge) (Word32.andb (0wxFF, word32))
  end

  local
    val MaxInt8 = 0x7F : Int8.int
    val MinInt8 = ~0x80 : Int8.int
  in
  fun int8ToWord32 (int8 : Int8.int) =
      if (MaxInt8 < int8) orelse (int8 < MinInt8)
      then raise E.OLEError (E.Conversion "cannot convert Int8 to Word32.")
      else Word32.andb (0wxFF, int32ToWord32 int8)
  fun word32ToInt8 word32 =
      if Word32.andb (word32, 0wx80) = 0w0
      then word32ToInt32 word32
      else word32ToInt32X (Word32.orb (0wxFFFFFF00, word32)) : Int8.int
  end

  val int8ToWord8 = word32ToWord8 o int8ToWord32
  val word8ToInt8 = word32ToInt8 o word8ToWord32

  fun word32ToWord8Quad word32 =
      let
        val byte1 = word32ToWord8 (Word32.andb(word32, 0wxFF))
        val byte2 = word32ToWord8 (Word32.andb(Word32.>>(word32, 0w8), 0wxFF))
        val byte3 = word32ToWord8 (Word32.andb(Word32.>>(word32, 0w16), 0wxFF))
        val byte4 = word32ToWord8 (Word32.andb(Word32.>>(word32, 0w24), 0wxFF))
      in (byte1, byte2, byte3, byte4)
      end
  fun word8QuadToWord32 (byte1, byte2, byte3, byte4) =
      let
        val value1 = word8ToWord32 byte1
        val value2 = Word32.orb (value1, Word32.<<(word8ToWord32 byte2, 0w8))
        val value3 = Word32.orb (value2, Word32.<<(word8ToWord32 byte3, 0w16))
        val value4 = Word32.orb (value3, Word32.<<(word8ToWord32 byte4, 0w24))
      in value4
      end

  local
    val MaxInt16 = 0x7FFF : Int16.int
    val MinInt16 = ~0x8000 : Int16.int
  in
  fun int16ToWord32 (int16 : Int16.int) =
      if (MaxInt16 < int16) orelse (int16 < MinInt16)
      then raise E.OLEError (E.Conversion "cannot convert Int16 to Word32.")
      else Word32.andb (0wxFFFF, int32ToWord32 int16)
  fun word32ToInt16 word32 =
      if Word32.andb (word32, 0wx8000) = 0w0
      then word32ToInt32 word32
      else word32ToInt32X (Word32.orb (0wxFFFF0000, word32)) : Int16.int
  end

  local
    val MaxWord16 = 0wxFFFF : Word32.word
  in
  fun word16ToWord32 (word16 : Word16.word) =
      if (MaxWord16 < word16)
      then
        raise
          E.OLEError
              (E.Conversion
                   ("can't convert Word16(" ^ Word16.toString word16 ^ ")"))
      else word16
  fun word32ToWord16 word32 = Word32.andb (0wxFFFF, word32) : Word16.word
  end

  local
    val MaxInt64 = 0x7FFFFFFFFFFFFFFF : IntInf.int
(* FIXME: 
   see http://www.pllab.riec.tohoku.ac.jp/hiki/smlsharp-dev/?Ticket-7
    val MinInt64 = ~0x8000000000000000 : IntInf.int
*)
    val MinInt64 = ~1 * 0x8000000000000000 : IntInf.int
  in
  fun wordsToInt64 (word1, word2) =
      let
        val higher = 
            if Word32.andb (word2, 0wx80000000) = 0w0
            then word32ToIntInf word2
            else word32ToIntInfX word2
        val lower = word32ToIntInf word1
      in
        IntInf.orb(IntInf.<< (higher, 0w32), lower)
      end
  fun int64ToWords int64 =
      if (int64 < MinInt64) orelse (MaxInt64 < int64)
      then
        raise
          E.OLEError
            (E.Conversion
                 ("can't convert Int64(" ^ IntInf.toString int64 ^ ")"))
      else
        (
          Word32.fromLargeInt (IntInf.andb (0xFFFFFFFF, int64)),
          Word32.fromLargeInt (IntInf.~>> (int64, 0w32))
        )
  end

  local
    val MaxWord64 = 0xFFFFFFFFFFFFFFFF : IntInf.int
    val MinWord64 = 0 : IntInf.int
  in
  fun wordsToWord64 (word1, word2) =
      let
        val higher = word32ToIntInf word2
        val lower = word32ToIntInf word1
      in
        IntInf.orb(IntInf.<< (higher, 0w32), lower)
      end
  fun word64ToWords word64 =
      if (word64 < MinWord64) orelse (MaxWord64 < word64)
      then
        raise
          E.OLEError
            (E.Conversion
                 ("can't convert Word64(" ^ IntInf.toString word64 ^ ")"))
      else
        (
          Word32.fromLargeInt (IntInf.andb (0xFFFFFFFF, word64)),
          Word32.fromLargeInt (IntInf.~>> (word64, 0w32))
        )
  end

  fun real32ToWord32 real32 =
      let
        val vec = PackReal32Little.toBytes real32
        val word = PackWord32Little.subVec (vec, 0)
      in word
      end

  fun word32ToReal32 word =
      let
        val array = Word8Array.array (4, 0w0)
        val _ = PackWord32Little.update (array, 0, word)
      in PackReal32Little.subArr(array, 0)
      end

  fun real64ToWord32Double real64 =
      let
        val vec = PackReal64Little.toBytes real64
        val word1 = PackWord32Little.subVec (vec, 0)
        val word2 = PackWord32Little.subVec (vec, 4)
      in (word1, word2)
      end

  fun word32DoubleToReal64 (word1, word2) =
      let
        val array = Word8Array.array (8, 0w0)
        val _ = PackWord32Little.update (array, 0, word1)
        val _ = PackWord32Little.update (array, 4, word2)
      in PackReal64Little.subArr(array, 0)
      end

  fun byteArrayToString array =
      Word8Array.foldli
          (fn (i, b, s) => s ^ Int.toString i ^ "=" ^ Word8.toString b ^ ",")
          "["
          array
      ^ "]"

  (****************************************)

end;