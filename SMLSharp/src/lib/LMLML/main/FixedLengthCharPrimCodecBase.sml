(**
 * generator of a primitive codec module for a codec.
 * <p>
 * It requires that the codec satisfies the following conditions.
 * <ul>
 *   <li>each character can be represented as a character code of a 32bit word.
 *     </li>
 *   <li>Character codes less than or equal to 127 are mapped to ASCII
 *     charset.</li>
 * </ul>
 * </p>
 * <p>
 * A string is represented as an array of 32 bit words.
 * And, a character is represented as a 32bit word.
 * </p>
 * <p>
 * Generally, a primitive codec module generated for a codec by this functor
 * is efficient than those generated for the codec by
 * VariableLengthCharPrimCodecBase.
 * </p>
 * @author YAMATODANI Kiyoshi
 * @version $Id: FixedLengthCharPrimCodecBase.sml,v 1.1 2006/12/11 10:57:04 kiyoshiy Exp $
 *)
functor FixedLengthCharPrimCodecBase
          (P
           : sig
               val names : String.string list
               val decode
                   : Word8VectorSlice.slice -> Word32.word VectorSlice.slice
               val encode
                   : Word32.word VectorSlice.slice -> Word8VectorSlice.slice
               val convert
                   : String.string
                     -> Word32.word VectorSlice.slice
                     -> Word8VectorSlice.slice
               val maxOrdw : Word32.word
             end) : PRIM_CODEC =
struct

  structure V = Vector
  structure VS = VectorSlice

  type string = Word32.word VS.slice
  type char = Word32.word

  val names = P.names

  val decode = P.decode
  val encode = P.encode
  val convert = P.convert

  val sub = VS.sub : string * int -> char
  fun substring (buffer, start, length) =
      VS.subslice (buffer, start, SOME length)
  val size = VS.length
  fun concat strings = VS.full(VS.concat strings)

  local
    fun mapCharPred f char = f (Char.chr(Word32.toInt char))
  in

  val compareChar = Word32.compare 

  val maxAscii = 0w127 : Word32.word
  fun minOrdw () = 0w0 : Word32.word
  fun maxOrdw () = P.maxOrdw
  fun ordw codepoint = codepoint
  fun chrw codepoint = codepoint

  fun toAsciiChar codepoint =
      if codepoint <= maxAscii
      then SOME(Char.chr (Word32.toInt codepoint))
      else NONE
  fun fromAsciiChar char = Word32.fromInt (Char.ord char)
  fun charToString codepoint = VS.full(V.fromList [codepoint])

  fun isAscii codepoint = codepoint <= maxAscii
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
