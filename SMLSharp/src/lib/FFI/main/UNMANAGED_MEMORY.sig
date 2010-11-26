(**
 * functions to access memory outside of the managed heap.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: UNMANAGED_MEMORY.sig,v 1.10 2007/03/09 23:17:08 kiyoshiy Exp $
 *)
signature UNMANAGED_MEMORY =
sig

  (***************************************************************************)

  (**
   * memory address outside of the managed heap.
   *)
  type address = unit ptr

  (***************************************************************************)

  (**
   * converts an address to a word.
   *)
  val addressToWord : address -> Word32.word

  (**
   * converts a word to an address.
   *)
  val wordToAddress : Word32.word -> address

  (** NULL pointer.
   *)
  val NULL : address

  (**
   * true if address is NULL pointer.
   *)
  val isNULL : address -> bool

  (**
   * advance a pointer forward or backward.
   * <code>advance (a, n)</code> is equivalent to
   * <pre>
   * if 0 <= n
   * then wordToAddress(addressToWord a + Word.fromInt(n))
   * else wordToAddress(addressToWord a - Word.fromInt(abs n))
   * </pre>
   *)
  val advance : address * int -> address

  (**
   * allocate an unmanaged memory region.
   * @params bytes
   * @param bytes the number of bytes
   * @return an address in unmanaged memory.
   *)
  val allocate : int -> address

  (**
   * release the memory allocated by 'allocate' and 'export'.
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
   * copy the contents of a byte vector to unmanaged memory.
   * The returned address must be released by 'release' after use.
   * @params byteVector
   * @param byteVector a vector in the heap.
   * @return an address in unmanaged memory of which contents is copied from
   *        the vector.
   *)
  val export : Word8Vector.vector -> address

  (**
   * copy the contents of a slice of a byte vector to unmanaged memory.
   * The returned address must be released by 'release' after use.
   * @params byteVector start length
   * @param byteVector a vector in the heap.
   * @param start the offset of the first byte to be exported.
   * @param length the number of bytes to be exported.
   * @return an address in unmanaged memory of which contents is copied from
   *        the vector.
   *)
  val exportSlice : Word8Vector.vector * int * int -> address

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

  (**
   * extracts an int from a unmanaged memory address.
   * @params address
   * @param address an address in unmanaged memory.
   * @return the word value at (int* )((byte* )address)
   *)
  val subInt : address -> Int32.int

  (**
   * stores an int into a unmanaged memory address.
   * @params (address, newValue)
   * @param address a pointer to a address in unmanaged memory.
   * @param newValue a word value which is stored into
   *                (int* )((byte* )address)
   *)
  val updateInt : (address * Int32.int) -> unit

  (**
   * extracts a real from a unmanaged memory address.
   * @params address
   * @param address an address in unmanaged memory.
   * @return the real value at (real* )((byte* )address)
   *)
  val subReal : address -> Real.real

  (**
   * stores a real into a unmanaged memory address.
   * @params (address, newValue)
   * @param address a pointer to a address in unmanaged memory.
   * @param newValue a real value which is stored into
   *                (real* )((byte* )address)
   *)
  val updateReal : (address * Real.real) -> unit

  (**
   * extracts a pointer from a unmanaged memory address.
   * @params address
   * @param address an address in unmanaged memory.
   * @return the real value at (void* )((byte* )address)
   *)
  val subPtr : address -> unit ptr

  (**
   * stores a pointer into a unmanaged memory address.
   * @params (address, newValue)
   * @param address a pointer to a address in unmanaged memory.
   * @param newValue a pointer value which is stored into
   *                (void* )((byte* )address)
   *)
  val updatePtr : (address * unit ptr) -> unit

  (***************************************************************************)

end
