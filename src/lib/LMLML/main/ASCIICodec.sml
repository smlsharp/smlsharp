local
  structure ASCIICodecPrim : PRIM_CODEC =
  struct

  structure V = Word8Vector
  structure VS = Word8VectorSlice

  type string = Codecs.buffer
  type char = Word8.word

  val names =
      [
        "ANSI_X3.4-1968",
        "iso-ir-6",
        "ANSI_X3.4-1986",
        "ISO_646.irv:1991",
        "ASCII",
        "ISO646-US",
        "US-ASCII",
        "us",
        "IBM367",
        "cp367",
        "csASCII"
      ]

  fun decode buffer = buffer
  fun encode string = string
  fun convert targetCodec chars = raise Codecs.ConverterNotFound

  val sub = VS.sub
  fun substring (buffer, start, length) =
      VS.subslice (buffer, start, SOME length)
  val size = VS.length
  fun concat strings = VS.full(VS.concat strings)

  local
    fun mapCharPred f char = f (Char.chr(Word8.toInt char))
  in

  val compareChar = Word8.compare 

  fun minOrdw () = 0w0 : Word32.word
  fun maxOrdw () = 0wxFF : Word32.word
  fun ordw byte = (Word32.fromLargeWord o Word8.toLargeWord) byte
  fun chrw charCode = (Word8.fromLargeWord o Word32.toLargeWord) charCode

  fun toAsciiChar byte = SOME(Char.chr (Word8.toInt byte))
  fun fromAsciiChar char = Word8.fromInt(Char.ord char)
  fun charToString char = VS.full(V.fromList [char])

  fun isAscii char = true
  val isSpace = mapCharPred Char.isSpace
  val isLower = mapCharPred Char.isLower
  val isUpper = mapCharPred Char.isUpper
  val isDigit = mapCharPred Char.isDigit
  val isHexDigit = mapCharPred Char.isHexDigit
  val isPunct = mapCharPred Char.isPunct
  val isGraph = mapCharPred Char.isGraph
  val isCntrl = mapCharPred Char.isCntrl
  end

end

in

(**
 * fundamental functions to access ASCII encoded characters.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ASCIICodec.sml,v 1.2 2007/02/17 06:30:15 kiyoshiy Exp $
 *)
structure ASCIICodec = Codec(ASCIICodecPrim)

end
