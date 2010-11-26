(**
 * pointer operations
 * @author UENO Katsuhiro
 * @copyright 2010, Tohoku University.
 *)
structure Pointer =
struct

  val advance : 'a ptr * int -> 'a ptr =
      SMLSharp.Pointer.advance

  val load = !!
  val store = '_Pointer_store'

  fun sub (ptr, n) = !! (advance (ptr, n))

  fun update (ptr, n, v) = store (advance (ptr, n), v)

  fun importBytes (ptr : Word8.word ptr, len : int) : Word8Vector.vector =
      let
        val ptr = _cast(ptr) : unit ptr
        val vec = SMLSharp.Runtime.UnmanagedMemory_import (ptr, len)
      in
        _cast(vec) : Word8Vector.vector
      end

  fun importString (ptr : char ptr) : string =
      let
        val ptr = _cast(ptr) : unit ptr
        val len = SMLSharp.Runtime.UnmanagedString_size ptr
        val vec = SMLSharp.Runtime.UnmanagedMemory_import (ptr, len)
      in
        vec
      end

end
