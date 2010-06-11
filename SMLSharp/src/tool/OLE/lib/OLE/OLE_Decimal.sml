(**
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: OLE.sml,v 1.27.22.2 2010/05/09 03:58:29 kiyoshiy Exp $
 *)
structure OLE_Decimal : OLE_DECIMAL =
struct

  structure BS = OLE_BufferStream

  structure WORD = Word32 (* 16 bit unsigned *)
  structure BYTE = Word8
  structure ULONG = Word32 (* 32 bit unsigned *)

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

  val VT_DECIMAL = 0w14 : Word8.word

  fun export embedInVariant (outstream, decimal) =
      let
        val (wReserved, sign, scale, Hi32, Lo32, Mid32) = makeFields decimal
        val outstream =
            if embedInVariant
            then BS.output (BS.output (outstream, VT_DECIMAL), 0w0)
            else BS.skipOut (outstream, 2)
        val outstream = BS.output (outstream, scale)
        val outstream = BS.output (outstream, sign)
        val outstream = BS.outputWord32 (outstream, Hi32)
        val outstream = BS.outputWord32 (outstream, Lo32)
        val outstream = BS.outputWord32 (outstream, Mid32)
      in
        outstream
      end

  val word32ToIntInf = IntInf.fromLarge o Word32.toLargeInt

  fun import instream =
      let
        val (_, instream) = BS.input instream
        val (_, instream) = BS.input instream
        val (scale, instream) = BS.input instream
        val (sign, instream) = BS.input instream
        val (Hi32, instream) = BS.inputWord32 instream
        val (Lo32, instream) = BS.inputWord32 instream
        val (Mid32, instream) = BS.inputWord32 instream
        val Hi32Int = word32ToIntInf Hi32
        val Lo32Int = word32ToIntInf Lo32
        val Mid32Int = word32ToIntInf Mid32
        val Lo64Int = IntInf.orb (IntInf.<< (Mid32Int, 0w32), Lo32Int)
        val value =
            (if sign = 0w0 then 1 else ~1)
            * IntInf.orb (IntInf.<< (Hi32Int, 0w64), Lo64Int)
      in
        ({scale = scale, value = value}, instream)
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
