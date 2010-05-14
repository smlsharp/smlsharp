local

  structure PU = PrimCodecUtil

  structure EUCJPCodecPrimArg = 
  struct

  val names = 
      [
        "Extended_UNIX_Code_Packed_Format_for_Japanese",
        "csEUCPkdFmtJapanese",
        "EUC-JP"
      ]

    datatype tag = C0 | C1 | C2 | C3

    fun tagToBytes tag =
        case tag
         of C0 => 1
          | C1 => 2
          | C2 => 2
          | C3 => 3

    val minOrdw = 0w0 : Word32.word
    val maxOrdw = 0wx8FFEFE : Word32.word

    fun getOrd (bytes, _) = PU.bytesToWord32 bytes
    fun encodeChar 0w0 = [0w0]
      | encodeChar charCode = PU.dropPrefixZeros (PU.word32ToBytes charCode)
    fun convert targetCodec chars = raise Codecs.ConverterNotFound

    val table =
        [
          (PU.Byte(0w0, 0w126), C0),
          (PU.Seq[PU.Byte(0w161, 0w254), PU.Byte(0w161, 0w254)], C1),
          (PU.Seq[PU.Byte(0w142, 0w142), PU.Byte(0w161, 0w223)], C2),
          (
            PU.Seq
                [
                  PU.Byte(0w143, 0w143),
                  PU.Byte(0w161, 0w254),
                  PU.Byte(0w161, 0w254)
                ],
            C3
          )
        ]

  end

in

(**
 * fundamental functions to access EUCJP encoded characters.
 * @author YAMATODANI Kiyoshi
 * @version $Id: EUCJPCodec.sml,v 1.1.28.1 2010/05/11 07:08:04 kiyoshiy Exp $
 *)
structure EUCJPCodec =
          Codec(VariableLengthCharPrimCodecBase(EUCJPCodecPrimArg))

end
