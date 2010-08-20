(**
 * MULTI_BYTE_CHAR signature specifies manipulations on multibyte character 
 * encoded in a particular encoding.
 * <p>
 * For the detail of module members, see the document for Basis CHAR signature.
 * </p>
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: MULTI_BYTE_CHAR.sig,v 1.1.2.4 2010/05/11 07:08:04 kiyoshiy Exp $
 *)
signature MULTI_BYTE_CHAR =
sig

  (**
   * The type of multibyte characters is not eqtype.
   * There may be cases where two multibyte characters encoded in different
   * byte sequences should be considered as semantically equal.
   * Use the <tt>compare</tt> to check semantic equality.
   *)
  type char

  (**
   * The type of multibyte strings is not eqtype.
   * There may be cases where two multibyte strings encoded in different
   * byte sequences should be considered as semantically equal.
   * Use the <tt>compare</tt> in the multibyte string module for the
   * corresponding codec to check semantic equality.
   *)
  type string

  exception Chr

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

  val succ : char -> char
  val pred : char -> char

  (** compare characters at two chars. *)
  val compare : char * char -> order
  val < : char * char -> bool
  val <= : char * char -> bool
  val > : char * char -> bool
  val >= : char * char -> bool

  val contains : string -> char -> bool
  val notContains : string -> char -> bool

  val isAscii : char -> bool
  val toLower : char -> char
  val toUpper : char -> char
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

(* FIXME
  val scan : (Char.char, 'a) StringCvt.reader -> (char, 'a) StringCvt.reader
*)

  val fromString : String.string -> char option 
  val toString : char -> String.string
  val fromCString : String.string -> char option 
  val toCString : char -> String.string

  val toAsciiChar : char -> Char.char option
  val fromAsciiChar : Char.char -> char

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
  val bytesSliceToMBC : Word8VectorSlice.slice -> char option

  (**
   * <p>
   * This is equivalent to
   * <pre>
   *   decodeBytes (MultiByteString.getDefaultCodecName ()) .
   * </pre>
   * </p>
   *)
  val bytesToMBC : Word8Vector.vector -> char option

  (**
   * <p>
   * This is equivalent to
   * <pre>
   *   bytesToMBC o Byte.stringToBytes
   * </pre>
   * </p>
   *)
  val stringToMBC : String.string -> char option

  val MBCToBytesSlice : char -> Word8VectorSlice.slice
  val MBCToBytes : char -> Word8Vector.vector
  val MBCToString : char -> String.string

  (**
   * generates a string representation of internal data structure.
   * This is for development utility.
   *)
  val dump : char -> String.string

end
