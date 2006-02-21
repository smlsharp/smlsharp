(**
 * functions to manipulate memory blocks which are allocated outside of the
 * managed heap.
 * @author YAMATODANI Kiyoshi
 * @version $Id: UnmanagedMemory.sml,v 1.2 2005/12/05 12:51:08 kiyoshiy Exp $
 *)
structure UnmanagedMemory : UNMANAGED_MEMORY =
struct

  (***************************************************************************)

  type address = Word32.word

  (***************************************************************************)

  val allocate = UnmanagedMemory_allocate

  val release = UnmanagedMemory_release

  fun import (memory, bytes) =
      let val byteArray = UnmanagedMemory_import (memory, bytes)
      in UnsafeCast byteArray : Word8Vector.vector
      end

  fun export vector = UnmanagedMemory_export (UnsafeCast vector : byteArray)

  val sub = UnmanagedMemory_sub

  val update = UnmanagedMemory_update

  val subWord = UnmanagedMemory_subWord

  val updateWord = UnmanagedMemory_updateWord

  (***************************************************************************)

end
