structure UnmanagedString : UNMANAGED_STRING =
struct

  (***************************************************************************)

  structure UM = UnmanagedMemory

  (***************************************************************************)

  (**
   * string allocated outside of the managed heap.
   *)
  type unmanagedString = UM.address

  (***************************************************************************)

  val size = UnmanagedString_size

  (**
   * copy an unmanaged string into the heap.
   *)
  fun import unmanagedString =
      Byte.bytesToString
          (UM.import
               (unmanagedString, size unmanagedString + (* for null char *) 1))
      
  (**
   * copy a string to unmanaged memory.
   * The retured unmanagedString must be released by releaseUnmanagedBlock
   * after use.
   *)
  val export = UM.export o Byte.stringToBytes

  (**
   * release the memory allocated by exportBlock.
   *)
  val release = UM.release

  fun sub (unmanagedString, index) =
      Char.chr(Word8.toInt(UM.sub (unmanagedString + Word32.fromInt index)))

  fun update (unmanagedString, index, value) =
      UM.update
          (
            unmanagedString + Word32.fromInt index,
            Word8.fromInt(Char.ord value)
          )

  (***************************************************************************)

end