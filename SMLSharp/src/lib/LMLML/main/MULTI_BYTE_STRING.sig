(**
 * MULTI_BYTE_STRING signature specifies manipulations on multibyte strings
 * which encode sequences of multibyte characters in a particular encoding.
 * <p>
 * This is almost similar to the STRING signature in Basis.
 * For the detail of module members, see the document for Basis STRING
 * signature.
 * </p>
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: MULTI_BYTE_STRING.sig,v 1.1.28.4 2010/05/11 07:08:04 kiyoshiy Exp $
 *)
signature MULTI_BYTE_STRING =
sig

  (**
   * The type of multibyte characters is not eqtype.
   * There may be cases where two multibyte characters encoded in different
   * byte sequences should be considered as semantically equal.
   * Use the <tt>compare</tt> in the multibyte character module for the
   * corresponding codec to check semantic equality.
   *)
  type char

  (**
   * The type of multibyte strings is not eqtype.
   * There may be cases where two multibyte strings encoded in different
   * byte sequences should be considered as semantically equal.
   * Use the <tt>compare</tt> to check semantic equality.
   *)
  type string

  (**
   * decodes a byte vector slice into a multibyte string according to default
   * codec.
   * <p>
   * This is equivalent to
   * <pre>
   *   decodeBytesSlice (MultiByteString.getDefaultCodecName ()) .
   * </pre>
   * </p>
   *)
  val bytesSliceToMBS : Word8VectorSlice.slice -> string

  (**
   * decodes a byte vector into a multibyte string according to default codec.
   * <p>
   * This is equivalent to
   * <pre>
   *   decodeBytes (MultiByteString.getDefaultCodecName ()) .
   * </pre>
   * </p>
   *)
  val bytesToMBS : Word8Vector.vector -> string

  (**
   * decodes a Basis string into a multibyte string according to default codec.
   * <p>
   * This is equivalent to
   * <pre>
   *   bytesToMBS o Byte.stringToBytes
   * </pre>
   * </p>
   *)
  val stringToMBS : String.string -> string

  (**
   * get a byte vector slice in which the string is encoded by the codec.
   * It has prefix and suffix if necessary to make the string canonical with
   * respect to the codec.
   *)
  val MBSToBytesSlice : string -> Word8VectorSlice.slice

  (**
   * get a byte array in which the string is encoded by the codec.
   * <p>
   * This is equivalent to
   * <pre>
   *   Word8VectorSlice.vector o MBSToBytesSlice
   * </pre>
   * </p>
   *)
  val MBSToBytes : string -> Word8Vector.vector

  (**
   * convert a multibyte string to a Basis string.
   * <p>
   * This is equivalent to
   * <pre>
   *   Byte.bytesToString o MBSToBytes.
   * </pre>
   * </p>
   *)
  val MBSToString : string -> String.string

  (**
   * converts a sequence of ASCII characters to a multibyte string.
   * <p>
   * This is equivalent to
   * <pre>
   *   implode o (map fromAsciiChar) o String.explode
   * </pre>
   * </p>
   *)
  val fromAsciiString : String.string -> string

  (**
   * converts a multibyte string to a sequence of ASCII characters.
   * Multibyte characters which are not in ASCII are converted to '?'.
   * <p>
   * This is equivalent to
   * <pre>
   *   String.implode
   *    o map (fn copt => Option.getOpt(toAsciiChar copt, #"?"))
   *    o explode
   * </pre>
   * </p>
   *)
  val toAsciiString : string -> String.string

(*
  (**
   * convert a string to another encoding.
   * @params targetCodec string
   * @param targetCodec the codec to which the mbs is converted.
   * @param string a multibyte string of this codec.
   * @return a byte vector slice in which the string is converted to the
   *          targetCodec.
   * @exception ConverterNotFound raised if targetCodec is not found.
   *)
  val convert : String.string -> string -> Word8VectorSlice.slice
*)
  val maxSize : int
  val size : string -> int
  val sub : string * int -> char
  val extract : string * int * int option -> string
  val substring : string * int * int -> string
  val ^ : string * string -> string
  val concat : string list -> string
  val concatWith : string -> string list -> string
  val str : char -> string
  val implode : char list -> string
  val explode : string -> char list
  val map : (char -> char) -> string -> string
  val translate : (char -> string) -> string -> string
  val tokens : (char -> bool) -> string -> string list
  val fields : (char -> bool) -> string -> string list
  val isPrefix : string -> string -> bool
  val isSubstring : string -> string -> bool
  val isSuffix : string -> string -> bool

  val < : string * string -> bool
  val <= : string * string -> bool
  val > : string * string -> bool
  val >= : string * string -> bool
  val compare : string * string -> order
  val collate : (char * char -> order) -> string * string -> order

(* FIXME
   StringCvt should be multi-byted version, but cyclic-reference will be 
  difficult to avoid.
  val scan : (char, 'a) StringCvt.reader -> (string, 'a) StringCvt.reader
*)
  val fromString : String.string -> string option 
  val toString : string -> String.string
  val fromCString : String.string -> string option 
  val toCString : string -> String.string

  (**
   * generates a string representation of internal data structure.
   * This is for development utility.
   *)
  val dump : string -> String.string

end
