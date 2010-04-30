(**
 * provides serialize/deserialize of bytes to/from a byte array.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PRIMITIVE_SERIALIZER.sig,v 1.5 2006/09/28 08:58:08 katsuu Exp $
 *)
signature PRIMITIVE_SERIALIZER =
sig

  (***************************************************************************)

  type reader = unit -> Word8.word
  type writer = Word8.word -> unit
  type word64 = IEEE754.word64

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

  (**
   * combine two 32bit integer into one 64bit integer.
   * @params (n1, n2)
   * @return a combined 64bit integer
   *)
  val toWord64 : Word32.word * Word32.word -> word64

  (**
   * split one 64bit integer to two 32bit integer.
   * @params n
   * @return a pair of 32bit integers
   *)
  val fromWord64 : word64 -> Word32.word * Word32.word

  (***************************************************************************)

end