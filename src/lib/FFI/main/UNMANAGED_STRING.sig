(**
 * functions to manipulate strings which are allocated outside of the managed
 * heap.
 * @author YAMATODANI Kiyoshi
 * @version $Id: UNMANAGED_STRING.sig,v 1.3 2006/11/04 13:16:37 kiyoshiy Exp $
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
   * @params address
   * @param address an unmanaged string
   * @return return value is equal to 'strlen(address)'.
   *)
  val size : unmanagedString -> int

  (**
   * copy an unmanaged string into the heap.
   * @params address
   * @param address an unmanaged string
   * @return a string in the managed heap whose contents is the same with
   *       those of 'address'.
   *)
  val import :  unmanagedString -> string

  (**
   * copy a string to unmanaged memory.
   * The retured unmanagedString must be released by 'release' after use.
   * @params string
   * @param string a string in the managed heap.
   * @return a string in unmanaged memory whose contents is the same with
   *       those of 'string'.
   *)
  val export : string -> unmanagedString

  (**
   * copy a string to unmanaged memory.
   * The retured unmanagedString must be released by 'release' after use.
   * @params substring
   * @param substring a substring in the managed heap.
   * @return a string in unmanaged memory whose contents is the same with
   *       those of 'substring'.
   *)
  val exportSubstring : substring -> unmanagedString

  (**
   * release the memory allocated by export.
   * @params address
   * @param address an unmanaged string
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
