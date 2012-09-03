structure UnmanagedString : UNMANAGED_STRING =
struct

  (***************************************************************************)

  structure UM = UnmanagedMemory

  (***************************************************************************)

  (**
   * string allocated outside of the managed heap.
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
   * The retured unmanagedString must be released by releaseUnmanagedBlock
   * after use.
   *)
  val export = UM.export o Byte.stringToBytes

  fun exportSubstring substring =
      let val (string, start, length) = Substring.base substring
      in UM.exportSlice (Byte.stringToBytes string, start, length)
      end

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
