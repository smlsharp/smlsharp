local

  structure PU = PrimCodecUtil

  structure ShiftJISCodecPrimArg = 
  struct

  val names = ["Shift_JIS", "MS_Kanji", "csShiftJIS"]

    datatype tag = ASCII | HANKAKU_KATAKANA | JIS_X_0208_1997

    fun tagToBytes tag =
        case tag
         of ASCII => 1
          | HANKAKU_KATAKANA => 1
          | JIS_X_0208_1997 => 2

    val minOrdw = 0w0 : Word32.word
    val maxOrdw = 0wxEFFC : Word32.word
    fun getOrd (bytes, _) = PU.bytesToWord32 bytes
    fun encodeChar 0w0 = [0w0]
      | encodeChar charCode = PU.dropPrefixZeros (PU.word32ToBytes charCode)
    fun convert targetCodec chars = raise Codecs.ConverterNotFound

    val table =
        [
          (PU.Byte(0w0, 0w126), ASCII),
          (PU.Byte(0w161, 0w223), HANKAKU_KATAKANA),
          (
            PU.Seq
                [
                  PU.Byte(0w129, 0w159),
                  PU.Or[PU.Byte(0w64, 0w126), PU.Byte(0w128, 0w252)]
                ],
            JIS_X_0208_1997
          ),
          (
            PU.Seq
                [
                  PU.Byte(0w224, 0w239),
                  PU.Or[PU.Byte(0w64, 0w126), PU.Byte(0w128, 0w252)]
                ],
            JIS_X_0208_1997)
        ]

  end

in

(**
 * fundamental functions to access ShiftJIS encoded characters.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: ShiftJISCodec.sml,v 1.1.28.1 2010/05/11 07:08:04 kiyoshiy Exp $
 *)
structure ShiftJISCodec :> CODEC =
          Codec(VariableLengthCharPrimCodecBase(ShiftJISCodecPrimArg))

end
