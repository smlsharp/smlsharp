(**
 * functions to manipulate strings which are allocated outside of the managed
 * heap.
 * @author YAMATODANI Kiyoshi
 * @version $Id: UNMANAGED_STRING.sig,v 1.2 2005/12/05 12:51:08 kiyoshiy Exp $
 *)
signature UNMANAGED_STRING =
sig

  (***************************************************************************)

  (**
   * string allocated outside of the managed heap.
   *)
  type unmanagedString

  (***************************************************************************)

  (**
   * the number of characters followed by a null character.
   *)
  val size : unmanagedString -> int

  (**
   * copy an unmanaged string into the heap.
   *)
  val import :  unmanagedString -> string

  (**
   * copy a string to unmanaged memory.
   * The retured unmanagedString must be released by releaseUnmanagedBlock
   * after use.
   *)
  val export : string -> unmanagedString

  (**
   * release the memory allocated by exportBlock.
   *)
  val release : unmanagedString -> unit

  (**
   * extracts a byte from a unmanaged memory address.
   * @params address
   * @param address an address in unmanaged memory.
   * @return a char value at ((char* )address)[offset]
   *)
  val sub : (unmanagedString * int) -> char

  (**
   * stores a byte into a unmanaged memory address.
   * @params (address, newValue)
   * @param address an address in unmanaged memory.
   * @param newValue a char value which is stored into ((char* )address)
   *)
  val update : (unmanagedString * int * char) -> unit

  (***************************************************************************)

end
