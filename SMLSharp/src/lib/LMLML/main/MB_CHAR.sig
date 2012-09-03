(**
 * MB_CHAR signature specifies manipulations on multibyte character 
 * encoded in a particular encoding.
 * <p>
 * For the detail of module members, see the document for Basis CHAR signature.
 * </p>
 * @author YAMATODANI Kiyoshi
 * @version $Id: MB_CHAR.sig,v 1.1 2006/12/11 10:57:04 kiyoshiy Exp $
 *)
signature MB_CHAR =
sig

  type char
  type string

  val minChar : unit -> char
  val maxChar : unit -> char
  val maxOrd : unit -> int

  val maxOrdw : unit -> Word32.word
  val minOrdw : unit -> Word32.word

  (**
   * This is equivalent to
   * <pre>
   *  Word32.toInt o ordw
   * </pre>
   * @exception Overflow 
   *)
  val ord : char -> int

  val ordw : char -> Word32.word

  (**
   * This is equivalent to
   * <pre>
   *  chrw o Word32.fromInt
   * </pre>
   *)
  val chr : int -> char

  (**
   * This is equivalent to
   * <pre>
   *  fromWord (MultiByteString.getDefaultCodecName ())
   * </pre>
   *)
  val chrw : Word32.word -> char

  (** compare characters at two chars. *)
  val compare : char * char -> order
  val < : char * char -> bool
  val <= : char * char -> bool
  val > : char * char -> bool
  val >= : char * char -> bool

  val contains : string -> char -> bool
  val notContains : string -> char -> bool

  val isAscii : char -> bool
  val isSpace : char -> bool
  val isLower : char -> bool
  val isUpper : char -> bool
  val isDigit : char -> bool
  val isAlpha : char -> bool
  val isHexDigit : char -> bool
  val isAlphaNum : char -> bool
  val isPrint : char -> bool
  val isPunct : char -> bool
  val isGraph : char -> bool
  val isCntrl : char -> bool

  val toString : char -> String.string
  val toAsciiChar : char -> Char.char option

  (**
   * decodes a byte vector slice into a multibyte character according to
   * default codec.
   * <p>
   * This is equivalent to
   * <pre>
   *   decodeBytesSlice (MultiByteString.getDefaultCodecName ()) .
   * </pre>
   * </p>
   *)
  val fromBytesSlice : Word8VectorSlice.slice -> char option

  (**
   * <p>
   * This is equivalent to
   * <pre>
   *   decodeBytes (MultiByteString.getDefaultCodecName ()) .
   * </pre>
   * </p>
   *)
  val fromBytes : Word8Vector.vector -> char option

  (**
   * <p>
   * This is equivalent to
   * <pre>
   *   fromBytes o Byte.stringToBytes
   * </pre>
   * </p>
   *)
  val fromString : String.string -> char option

  val fromAsciiChar : Char.char -> char

end
