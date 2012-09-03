(**
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: OLE.sml,v 1.27.22.2 2010/05/09 03:58:29 kiyoshiy Exp $
 *)
structure OLE_Decimal : OLE_DECIMAL =
struct

  structure WORD = Word32 (* 16 bit unsigned *)
  structure BYTE = Word8
  structure ULONG = Word32 (* 32 bit unsigned *)
  structure BYTES = Word8Array
  structure UM = UnmanagedMemory

  type decimal =
       {
         scale : Word8.word,
         value : IntInf.int
       }

  val SIZE_OF_DECIMAL = 16
  val MIN_SCALE = 0w0 : BYTE.word
  val MAX_SCALE = 0w28 : BYTE.word
  val MAX_ABS_VALUE = 0xFFFFFFFFFFFFFFFFFFFFFFFF : IntInf.int

  val MAX_VALUE = MAX_ABS_VALUE
  val MIN_VALUE = ~1 * MAX_ABS_VALUE

  fun makeFields {scale, value} =
      let
        val wReserved = 0w0 : WORD.word
        val sign = if 0 <= value then 0w0 else 0wx80 : BYTE.word
        val scale =
            if MIN_SCALE <= scale andalso scale <= MAX_SCALE
            then scale
            else raise Overflow
        val absValue = IntInf.abs value
        val _ = if MAX_ABS_VALUE < absValue then raise Overflow else ()
        val Hi32Int =
            IntInf.~>>
                    (IntInf.andb (absValue, 0xFFFFFFFF0000000000000000), 0w64)
        val Hi32 = ULONG.fromLargeInt Hi32Int
        val Mid32Int =
            IntInf.~>>(IntInf.andb (absValue, 0xFFFFFFFF00000000), 0w32)
        val Mid32 = ULONG.fromLargeInt Mid32Int
        val Lo32Int = IntInf.andb (absValue, 0xFFFFFFFF)
        val Lo32 = ULONG.fromLargeInt Lo32Int
      in
        (wReserved, sign, scale, Hi32, Lo32, Mid32)
      end

  fun exportArray decimal =
      let
        val (wReserved, sign, scale, Hi32, Lo32, Mid32) = makeFields decimal
        val buffer = BYTES.array (SIZE_OF_DECIMAL, 0w0)
        val _ = BYTES.update (buffer, 2, scale)
        val _ = BYTES.update (buffer, 3, sign)
        val _ = PackWord32Little.update (buffer, 1, Hi32)
        (* Serialize a 64bit unsigned as a sequence of two 32bit unsigned.
         * Serialize the lower 32bit first, because little endian is assumed.
         *)
        val _ = PackWord32Little.update (buffer, 2, Lo32)
        val _ = PackWord32Little.update (buffer, 3, Mid32)
      in
        buffer
      end

  fun export decimal address =
      let
        fun advance offset = UM.advance (address, offset)
        val (wReserved, sign, scale, Hi32, Lo32, Mid32) = makeFields decimal
        val _ = UM.update (advance 2, scale)
        val _ = UM.update (advance 3, sign)
        val _ = UM.updateWord (advance 4, Hi32)
        val _ = UM.updateWord (advance 8, Lo32)
        val _ = UM.updateWord (advance 12, Mid32)
      in
        ()
      end

  val word32ToIntInf = IntInf.fromLarge o Word32.toLargeInt
  val subArrWord32 = Word32.fromLargeWord o PackWord32Little.subArr
  val subUMWord32 = UM.subWord

  fun importArray buffer =
      let
        val scale = BYTES.sub (buffer, 2)
        val sign = BYTES.sub (buffer, 3)
        val Hi32 = subArrWord32 (buffer, 1)
        val Lo32 = subArrWord32 (buffer, 2)
        val Mid32 = subArrWord32 (buffer, 3)
        val Hi32Int = word32ToIntInf Hi32
        val Lo32Int = word32ToIntInf Lo32
        val Mid32Int = word32ToIntInf Mid32
        val Lo64Int = IntInf.orb (IntInf.<< (Mid32Int, 0w32), Lo32Int)
        val value =
            (if sign = 0w0 then 1 else ~1)
            * IntInf.orb (IntInf.<< (Hi32Int, 0w64), Lo64Int)
      in
        {scale = scale, value = value}
      end

  fun importWordArray (buffer, offset) =
      let
        val scaleSign = Array.sub (buffer, offset)
        val scaleWord = Word32.>>(Word32.andb (0wxFF0000, scaleSign), 0w16)
        val scale = (Word8.fromLarge o Word32.toLarge) scaleWord
        val sign = Word32.>>(Word32.andb (0wxFF000000, scaleSign), 0w24)
        val Hi32 = Array.sub (buffer, offset + 1)
        val Lo32 = Array.sub (buffer, offset + 2)
        val Mid32 = Array.sub (buffer, offset + 3)
        val Hi32Int = word32ToIntInf Hi32
        val Lo32Int = word32ToIntInf Lo32
        val Mid32Int = word32ToIntInf Mid32
        val Lo64Int = IntInf.orb (IntInf.<< (Mid32Int, 0w32), Lo32Int)
        val value =
            (if sign = 0w0 then 1 else ~1)
            * IntInf.orb (IntInf.<< (Hi32Int, 0w64), Lo64Int)
      in
        {scale = scale, value = value}
      end

  fun import address =
      let
        fun advance offset = UM.advance (address, offset)
        val scale = UM.sub (advance 2)
        val sign = UM.sub (advance 3)
        val Hi32 = subUMWord32 (advance 4)
        val Lo32 = subUMWord32 (advance 8)
        val Mid32 = subUMWord32 (advance 12)
        val Hi32Int = word32ToIntInf Hi32
        val Lo32Int = word32ToIntInf Lo32
        val Mid32Int = word32ToIntInf Mid32
        val Lo64Int = IntInf.orb (IntInf.<< (Mid32Int, 0w32), Lo32Int)
        val value =
            (if sign = 0w0 then 1 else ~1)
            * IntInf.orb (IntInf.<< (Hi32Int, 0w64), Lo64Int)
      in
        {scale = scale, value = value}
      end

  fun toString {scale, value} =
      "{scale = " ^ Word8.toString scale ^ ", \
      \value = " ^ IntInf.toString value ^ "}"

  fun compare (x : decimal, y : decimal) =
      let
        (* If
         *   x = {scale = 2, value = 123}, y = {scale = 3, value = 234},
         * then adjust scale factor as
         *   x = {scale = 3, value = 1230}, y = {scale = 3, value = 234},
         * and compare values.
         *)
        val scaleDiff = Word8.toInt (#scale x) - Word8.toInt (#scale y)
        val xvalue' =
            if 0 < scaleDiff
            then #value x
            else #value x * IntInf.pow(10, ~scaleDiff)
        val yvalue' =
            if scaleDiff < 0
            then #value y
            else #value y * IntInf.pow(10, scaleDiff)
      in
        IntInf.compare (xvalue', yvalue')
      end

end;
