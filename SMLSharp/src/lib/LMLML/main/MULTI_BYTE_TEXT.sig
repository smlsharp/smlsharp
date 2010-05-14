(**
 * The main user interface of the multibyte text library.
 * <p>
 * Features are:
 * <ul>
 *   <li>Codec can be selected at runtime.</li>
 *   <li>Multibyte character version of subsets of Basis String, Char and
 *      Substring are provided.</li>
 *   <li>Third party can extends the library by adding a new codec.</li>
 * </ul>
 * </p>
 * @author YAMATODANI Kiyoshi
 * @version $Id: MULTI_BYTE_TEXT.sig,v 1.1.2.2 2010/05/06 06:51:47 kiyoshiy Exp $
 *)
signature MULTI_BYTE_TEXT =
sig

  (**
   * codec used to encode characters.
   *)
  type codec

  (**
   * indicates failure of decoding due to malformed byte sequence.
   *)
  exception BadFormat

  (**
   * indicates that two cursors on different byte arrays or two characters of
   * different encodings are compared.
   *)
  exception Unordered

  (**
   * indicates no codec of the specified name is available.
   *)
  exception UnknownCodec

  (**
   * returns a list of registered codec names.
   *)
  val getCodecNames : unit -> String.string list

  (**
   * returns a codec specified by the name.
   * @params name
   * @param name name of a codec
   * @exception UnknownCodec raised if no codec of the specified name is found.
   *)
  val getCodec : String.string -> codec

  (**
   * changes the default codec.
   * @params codec
   * @param codec a codec
   *)
  val setDefaultCodec : codec -> unit

  (**
   * adds a listener function to receive changes of default codec.
   * When the default codec is changed, all listeners are invoked with the
   * new default codec as an argument .
   *)
  val addDefaultCodecChangeListener : (codec -> unit) -> unit

  (**
   * gets name of the current default codec.
   * Initially, the default codec is "ASCII".
   * The default codec can be changed by <code>setDefaultCodec</code>
   * function.
   * @return the current default codec.
   *)
  val getDefaultCodec : unit -> codec

  structure Char : 
  sig 

    include MULTI_BYTE_CHAR

    (**
     * Requirement that the following equation holds:
     * <pre>
     *   word == ordw (fromWord codec word)
     * </pre>
     * @params codec word
     * @param codec codec
     * @param word a 32-bit word
     *)
    val fromWord : codec -> Word32.word -> char

    (**
     * decodes a byte vector slice into a multibyte character.
     * @params codec slice
     * @param codec codec
     * @param slice a byte vector slice
     * @return the first character in the vector. NONE if the string is empty.
     *)
    val decodeBytesSlice : codec -> Word8VectorSlice.slice -> char option

    (**
     * convert a byte array to a multibyte charcter.
     * @params codec bytes
     * @param codec codec
     * @param bytes a byte vector
     * @return the first character in the vector. NONE if the string is empty.
     *)
    val decodeBytes : codec -> Word8Vector.vector -> char option

    (**
     * convert a Basis string to a multibyte charcter.
     * <p>
     * This is equivalent to
     * <pre>
     *   decodeBytes codec o Byte.stringToBytes  .
     * </pre>
     * </p>
     * @params codec string
     * @param codec codec
     * @param string basis string
     * @return the first character in the string. NONE if the string is empty.
     *)
    val decodeString : codec -> String.string -> char option

    (**
     * returns the codec used to decode the character.
     * @params char
     * @param char a multibyte character
     *)
    val getCodec : char -> codec

  end

  structure String : 
  sig

    include MULTI_BYTE_STRING

    (**
     * decodes a byte vector slice into a multibyte string.
     * @params codec slice
     * @param codec codec
     * @param slice a byte vector slice
     *)
    val decodeBytesSlice : codec -> Word8VectorSlice.slice -> string

    (**
     * decodes a byte vector into a multibyte string.
     * <p>
     * This is equivalent to
     * <pre>
     *   (decodeBytesSlice codec) o Word8VectorSlice.full
     * </pre>
     * </p>
     * @params codec bytes
     * @param codec codec
     * @param bytes a byte vector
     *)
    val decodeBytes : codec -> Word8Vector.vector -> string

    (**
     * decodes a Basis string into a multibyte string.
     * <p>
     * This is equivalent to
     * <pre>
     *   (decodeBytes codec) o Byte.stringToBytes
     * </pre>
     * </p>
     * @params codec bytes
     * @param codec codec
     * @param bytes a byte vector
     *)
    val decodeString : codec -> String.string -> string

    (**
     * returns the codec used to decode the string.
     * @params string
     * @param string a multibyte string.
     *)
    val getCodec : string -> codec

  end

  structure Substring : MULTI_BYTE_SUBSTRING

  structure ParserCombinator : MULTI_BYTE_PARSER_COMBINATOR

  structure StringConverter : MULTI_BYTE_STRING_CONVERTER

  sharing type Char.string = String.string
  sharing type Char.char = String.char
  sharing type Substring.string = String.string
  sharing type Substring.char = String.char
  sharing type ParserCombinator.string = String.string
  sharing type ParserCombinator.char = String.char
  sharing type StringConverter.string = String.string
  sharing type StringConverter.char = String.char

end;
