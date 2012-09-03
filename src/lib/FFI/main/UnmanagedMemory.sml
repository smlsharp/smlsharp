(**
 * functions to manipulate memory blocks which are allocated outside of the
 * managed heap.
 * @author YAMATODANI Kiyoshi
 * @version $Id: UnmanagedMemory.sml,v 1.11 2007/04/02 09:42:29 katsu Exp $
 *)
structure UnmanagedMemory : UNMANAGED_MEMORY =
struct

  (***************************************************************************)

  type address = unit ptr

  (***************************************************************************)

  fun addressToWord address = _cast(address) : Word32.word

  fun wordToAddress word = _cast(word) : address

  val NULL = NULL : address

  fun isNULL address = NULL = address

  fun advance (address : address, offset) =
      _cast((_cast(address) : Int32.int) + offset) : address

  val allocate = UnmanagedMemory_allocate

  val release = UnmanagedMemory_release

  fun import (memory, bytes) =
      (* NOTE: trailing '\0' character is appended by UnmanagedMemory_import.
       * This is necessary because Word8Vector.vector and string share the
       * same internal representation. *)
      let val byteArray = UnmanagedMemory_import (memory, bytes)
      in _cast(byteArray) : Word8Vector.vector
      end

  fun exportSlice (vector, start, length) =
      UnmanagedMemory_export (_cast(vector) : byteArray, start, length)

  fun export vector = exportSlice (vector, 0, Word8Vector.length vector)

  val sub = UnmanagedMemory_sub

  val update = UnmanagedMemory_update

  val subWord = UnmanagedMemory_subWord

  val updateWord = UnmanagedMemory_updateWord

  val subInt = UnmanagedMemory_subInt

  val updateInt = UnmanagedMemory_updateInt

  val subReal = UnmanagedMemory_subReal

  val updateReal = UnmanagedMemory_updateReal

  (***************************************************************************)

end
