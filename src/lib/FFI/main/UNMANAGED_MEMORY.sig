(**
 * functions to manipulate memory outside of the managed heap.
 * @author YAMATODANI Kiyoshi
 * @version $Id: UNMANAGED_MEMORY.sig,v 1.1 2006/03/01 15:56:08 kiyoshiy Exp $
 *)
signature UNMANAGED_MEMORY =
sig

  (***************************************************************************)

  (**
   * memory address outside of the managed heap.
   *)
  type address = Word32.word

  (***************************************************************************)

  (**
   * allocate an unmanaged memory region.
   * @params bytes
   * @param bytes the number of bytes
   * @return address an address in unmanaged memory.
   *)
  val allocate : int -> address

  (**
   * release the memory allocated by exportAddress.
   * @params address
   * @param address an address in unmanaged memory.
   *)
  val release : address -> unit

  (**
   * copy the contents of an unmanaged memory region into the heap.
   * @params (address, bytes)
   * @param address an address in unmanaged memory.
   * @param bytes the number of bytes in the address
   * @return a vector allocated in the heap of which contents is copied from
   *        the unmanaged address.
   *)
  val import : address * int -> Word8Vector.vector

  (**
   * copy the byte vector to unmanaged memory.
   * The retured address must be released by releaseUnmanagedAddress
   * after use.
   * @params byteVector
   * @param byteVector a vector in the heap.
   * @return an address in unmanaged memory of which contents is copied from
   *        the vector.
   *)
  val export : Word8Vector.vector -> address

  (**
   * extracts a byte from a unmanaged memory address.
   * @params address
   * @param address an address in unmanaged memory.
   * @return the byte value at ((byte* )address)[offset]
   *)
  val sub : address -> Word8.word

  (**
   * stores a byte into a unmanaged memory address.
   * @params (address, newValue)
   * @param address an address in unmanaged memory.
   * @param newValue a byte value which is stored into ((byte* )address)
   *)
  val update : (address * Word8.word) -> unit

  (**
   * extracts a word from a unmanaged memory address.
   * @params address
   * @param address an address in unmanaged memory.
   * @return the word value at (word* )((byte* )address)
   *)
  val subWord : address -> Word32.word

  (**
   * stores a word into a unmanaged memory address.
   * @params (address, newValue)
   * @param address a pointer to a address in unmanaged memory.
   * @param newValue a word value which is stored into
   *                (word* )((byte* )address)
   *)
  val updateWord : (address * Word32.word) -> unit

  (***************************************************************************)

end
