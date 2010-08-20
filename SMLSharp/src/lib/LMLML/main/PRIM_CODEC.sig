(**
 * PRIM_CODEC signature specifies fundamental functions to access multibyte
 * characters in a particular encoding.
 *
 * <h4>note about classification of characters.</h4>            
 * <p>
 * Characters are classified as follows.
 * <pre>
 *   +-- control
 *   +-- printable
 *         +-- space
 *         +-- graphical
 *               +-- punctuation
 *               +-- decimal digit
 *               +-- alphabet
 *               |     +-- lower
 *               |     +-- upper
 *               +-- other  (including kanji, kana, hangul characters.)
 * </pre>
 * And, a character of code between 0 and 127 is an ascii character.
 * </p>
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: PRIM_CODEC.sig,v 1.1.28.2 2010/05/11 07:08:04 kiyoshiy Exp $
 *)
signature PRIM_CODEC =
sig

  type char
  type string

  (**
   * codec name and aliase names.
   * They should be selected from the IANA charset registry.
   * <p>
   *   http://www.iana.org/assignments/character-sets
   * </p>
   *)
  val names : String.string list

  (**
   * decodes a byte array into a multibyte string.
   * @return a decoded string.
   *)
  val decode : Codecs.buffer -> string

  (**
   * encodes a multibyte string into a byte array.
   * @return an encoded byte array.
   *)
  val encode : string -> Codecs.buffer

  (**
   * convert a string to another encoding.
   * @params targetCodec string
   * @param targetCodec the codec to which the mbs is converted.
   * @param string a multibyte string of this codec.
   * @return a byte vector slice in which the string is converted to the
   *          targetCodec.
   * @exception ConverterNotFound raised if targetCodec is not found.
   *)
  val convert : String.string -> string -> Codecs.buffer

  val sub : string * int -> char
  val substring : string * int * int -> string
  val size : string -> int
  val maxSize : int
  val concat : string list -> string

  (**
   * comare two characters just after the cursors.
   * <p>
   * Semantics of the order on characters depends on the codec.
   * </p>
   * @params (left, right)
   * @param left a cursor.
   * @param right the other.
   * @return LESS if left < right, EQUAL if left = right,
   *         GREATER if left > right.
   * @exception Codecs.Unordered raised if no order relation is defined on the
   *                            two characters.
   *)
  val compareChar : char * char -> order

  val ordw : char -> Word32.word
  val chrw: Word32.word -> char

  val minOrdw : unit -> Word32.word
  val maxOrdw : unit -> Word32.word

  val charToString : char -> string
  val toAsciiChar : char -> Char.char option
  val fromAsciiChar : Char.char -> char

  val isAscii : char -> bool
  val isSpace : char -> bool
  val isLower : char -> bool
  val isUpper : char -> bool
  val isDigit : char -> bool
  val isHexDigit : char -> bool
  val isPunct : char -> bool
  val isGraph : char -> bool
  val isCntrl : char -> bool

  (**
   * generates a string representation of internal data structure of
   * a multibyte character.
   * This is for development utility.
   *)
  val dumpChar : char -> String.string

  (**
   * generates a string representation of internal data structure of
   * a multibyte string.
   * This is for development utility.
   *)
  val dumpString : string -> String.string

end;
