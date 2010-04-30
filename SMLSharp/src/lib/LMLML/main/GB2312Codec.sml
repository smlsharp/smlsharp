local

  structure PU = PrimCodecUtil

  structure GB2312CodecPrimArg = 
  struct

  val names = 
      [
        "GB2312", "csGB2312"
      ]

    datatype tag = C0 | C1

    fun tagToBytes tag =
        case tag
         of C0 => 1
          | C1 => 2

    val minOrdw = 0w0 : Word32.word
    val maxOrdw = 0wxFFFF : Word32.word
    fun getOrd (bytes, _) = PU.bytesToWord32 bytes
    fun encodeChar charCode = PU.dropPrefixZeros (PU.word32ToBytes charCode)
    fun convert targetCodec chars = raise Codecs.ConverterNotFound

    val table =
        [
          (PU.Byte(0w0, 0w126), C0),
          (PU.Seq[PU.Byte(0w161, 0w254), PU.Byte(0w161, 0w254)], C1)
        ]

  end

in

(**
 * fundamental functions to access GB2312 encoded characters.
 * @author YAMATODANI Kiyoshi
 * @version $Id: GB2312Codec.sml,v 1.1 2006/12/11 10:57:04 kiyoshiy Exp $
 *)
structure GB2312Codec =
          Codec(VariableLengthCharPrimCodecBase(GB2312CodecPrimArg))

end
