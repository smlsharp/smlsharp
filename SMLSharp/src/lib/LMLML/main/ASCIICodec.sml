local
  structure ASCIICodecPrim : PRIM_CODEC =
  struct

  structure V = Word8Vector
  structure VS = Word8VectorSlice

  type string = Word8VectorSlice.slice
  type char = Word8.word

  fun dumpString slice =
      let
        val strings = List.map Word8.toString (VS.foldr (op ::) [] slice)
        val string = String.concatWith ", " strings
      in
        "[" ^ string ^ "]"
      end
      
  fun dumpChar byte = Word8.toString byte

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
  val maxSize = V.maxLen
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
  fun isSpace x = mapCharPred Char.isSpace x
  fun isLower x = mapCharPred Char.isLower x
  fun isUpper x = mapCharPred Char.isUpper x
  fun isDigit x = mapCharPred Char.isDigit x
  fun isHexDigit x = mapCharPred Char.isHexDigit x
  fun isPunct x = mapCharPred Char.isPunct x
  fun isGraph x = mapCharPred Char.isGraph x
  fun isCntrl x = mapCharPred Char.isCntrl x
  end

end

in

(**
 * fundamental functions to access ASCII encoded characters.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: ASCIICodec.sml,v 1.2.28.3 2010/05/11 07:08:03 kiyoshiy Exp $
 *)
structure ASCIICodec :> CODEC = Codec(ASCIICodecPrim)

end
