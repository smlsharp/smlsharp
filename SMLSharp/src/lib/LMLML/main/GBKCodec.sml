local

  structure PU = PrimCodecUtil

  structure GBKCodecPrimArg = 
  struct

    val names = ["GBK", "CP936", "MS936", "windows-936"]

    datatype tag = ASCII | GBK

    fun tagToBytes tag =
        case tag
         of ASCII => 1
          | GBK => 2

    val minOrdw = 0w0 : Word32.word
    val maxOrdw = 0wxFEFE : Word32.word
    fun getOrd (bytes, _) = PU.bytesToWord32 bytes
    fun encodeChar 0w0 = [0w0]
      | encodeChar charCode = PU.dropPrefixZeros (PU.word32ToBytes charCode)
    fun convert targetCodec chars = raise Codecs.ConverterNotFound

    val table =
        [
          (PU.Byte(0w0, 0w127), ASCII),
          (
            PU.Seq
                [
                  PU.Byte(0w129, 0w254),
                  PU.Or[PU.Byte(0w64, 0w126), PU.Byte(0w128, 0w254)]
                ],
            GBK
          )
        ]

  end

in

(**
 * fundamental functions to access GBK encoded characters.
 * @author YAMATODANI Kiyoshi
 * @version $Id: GBKCodec.sml,v 1.1.28.1 2010/05/11 07:08:04 kiyoshiy Exp $
 *)
structure GBKCodec :> CODEC =
          Codec(VariableLengthCharPrimCodecBase(GBKCodecPrimArg))

end
