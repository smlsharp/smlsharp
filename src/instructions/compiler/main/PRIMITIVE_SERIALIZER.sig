(**
 * provides serialize/deserialize of bytes to/from a byte array.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PRIMITIVE_SERIALIZER.sig,v 1.4 2005/12/31 10:22:00 kiyoshiy Exp $
 *)
signature PRIMITIVE_SERIALIZER =
sig

  (***************************************************************************)

  type reader = unit -> Word8.word
  type writer = Word8.word -> unit

  (** the byte order which this serializer assumes. *)
  val byteOrder : SystemDefTypes.byteOrder

  (**
   * write lower bytes of a word into a byte array.
   * @params (word, bytes)
   * @param word a word value whose lower bytes are written to the array.
   * @param bytes a number of bytes to be written to the array
   * @return unit
   *)
  val writeLowBytes : (Word32.word * int) -> writer -> unit

  (**
   * read bytes from a byte array.
   * @params array bytes
   * @param bytes a number of bytes to be read out of the array
   * @return a value obtained out of the array
   *)
  val readBytes : int -> reader -> Word32.word

  (***************************************************************************)

end