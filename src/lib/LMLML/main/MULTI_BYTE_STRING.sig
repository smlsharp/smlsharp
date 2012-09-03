(**
 * The main user interface of the multibyte string library.
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
 * @version $Id: MULTI_BYTE_STRING.sig,v 1.1 2006/12/11 10:57:04 kiyoshiy Exp $
 *)
signature MULTI_BYTE_STRING =
sig

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
  val getCodecNames : unit -> string list

  (**
   * changes the default codec.
   * @params codec
   * @param codec name of a codec
   * @exception UnknownCodec raised if no codec of the specified name is found.
   *)
  val setDefaultCodecName : string -> unit

  (**
   * adds a listener function to receive changes of default codec.
   * When the default codec is changed, all listeners are invoked with the
   * name of new default codec as an argument .
   *)
  val addDefaultCodecChangeListener : (string -> unit) -> unit

  (**
   * gets name of the current default codec.
   * Initially, the default codec is "ASCII".
   * The default codec can be changed by <code>setDefaultCodecName</code>
   * function.
   * @return name of the current default codec.
   *)
  val getDefaultCodecName : unit -> string

  structure Char : 
  sig 

    include MB_CHAR

    (**
     * Requirement that the following equation holds:
     * <pre>
     *   word == ordw (fromWord codec word)
     * </pre>
     * @params codec word
     * @param codec the name of codec
     * @param word a 32-bit word
     *)
    val fromWord : String.string -> Word32.word -> char

    (**
     * decodes a byte vector slice into a multibyte character.
     * @params codec slice
     * @param codec codec name
     * @param slice a byte vector slice
     * @return the first character in the vector. NONE if the string is empty.
     * @exception MultiByteString.UnknownCodec raised if any codec of the
     *         specified name is not available.
     *)
    val decodeBytesSlice
        : String.string -> Word8VectorSlice.slice -> char option

    (**
     * convert a byte array to a multibyte charcter.
     * @params codec bytes
     * @param codec codec name
     * @param bytes a byte vector
     * @return the first character in the vector. NONE if the string is empty.
     * @exception MultiByteString.UnknownCodec raised if any codec of the
     *         specified name is not available.
     *)
    val decodeBytes : String.string -> Word8Vector.vector -> char option

    (**
     * convert a Basis string to a multibyte charcter.
     * <p>
     * This is equivalent to
     * <pre>
     *   decodeBytes codecName o Byte.stringToBytes  .
     * </pre>
     * </p>
     * @params codec string
     * @param codec codec name
     * @param string basis string
     * @return the first character in the string. NONE if the string is empty.
     * @exception MultiByteString.UnknownCodec raised if any codec of the
     *         specified name is not available.
     *)
    val decodeString : String.string -> String.string -> char option

  end

  structure String : 
  sig

    include MB_STRING

    (**
     * decodes a byte vector slice into a multibyte string.
     * @params codec slice
     * @param codec codec name
     * @param slice a byte vector slice
     * @exception MultiByteString.UnknownCodec raised if any codec of the
     *         specified name is not available.
     *)
    val decodeBytesSlice : String.string -> Word8VectorSlice.slice -> string

    (**
     * decodes a byte vector into a multibyte string.
     * <p>
     * This is equivalent to
     * <pre>
     *   (decodeBytesSlice codec) o Word8VectorSlice.full
     * </pre>
     * </p>
     * @params codec bytes
     * @param codec codec name
     * @param bytes a byte vector
     * @exception MultiByteString.UnknownCodec raised if any codec of the
     *         specified name is not available.
     *)
    val decodeBytes : String.string -> Word8Vector.vector -> string

    (**
     * decodes a Basis string into a multibyte string.
     * <p>
     * This is equivalent to
     * <pre>
     *   (decodeBytes codec) o Byte.stringToBytes
     * </pre>
     * </p>
     * @params codec bytes
     * @param codec codec name
     * @param bytes a byte vector
     * @exception MultiByteString.UnknownCodec raised if any codec of the
     *         specified name is not available.
     *)
    val decodeString : String.string -> String.string -> string

  end

  sharing type Char.string = String.string
  sharing type Char.char = String.char

end;
