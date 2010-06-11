(**
 * interface to null-terminated strings allocated outside of the managed heap
 * of SML#.
 * @author YAMATODANI Kiyoshi
 * @version $Id: UNMANAGED_STRING.sig,v 1.3 2006/11/04 13:16:37 kiyoshiy Exp $
 *)
structure UnmanagedString : UNMANAGED_STRING =
struct

  (***************************************************************************)

  structure UM = UnmanagedMemory

  (***************************************************************************)

  (**
   * null-terminated string allocated outside of the managed heap.
   *)
  type unmanagedString = unit ptr

  (***************************************************************************)

  val size = SMLSharp.Runtime.UnmanagedString_size

  (**
   * copy an unmanaged string into the heap.
   *)
  fun import unmanagedString =
      (* NOTE: trailing '\0' character is appended by UM.import. *)
      Byte.bytesToString (UM.import (unmanagedString, size unmanagedString))
      
  (**
   * copy a string to unmanaged memory.
   * The returned unmanagedString must be released by releaseUnmanagedBlock
   * after use.
   *)
  fun export string = (UM.export o Byte.stringToBytes) (string ^ "\000")

  val exportSubstring = export o Substring.string

  (**
   * release the memory allocated by exportBlock.
   *)
  val release = UM.release

  fun sub (unmanagedString:unmanagedString, index) =
      Char.chr(Word8.toInt(UM.sub ( _cast( (_cast(unmanagedString)) + Word32.fromInt index))))

  fun update (unmanagedString:unmanagedString, index, value) =
      UM.update
          (
            _cast((_cast(unmanagedString)) + Word32.fromInt index),
            Word8.fromInt(Char.ord value)
          )

  (***************************************************************************)

end
