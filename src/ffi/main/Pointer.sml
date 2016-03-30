(**
 * pointer operations
 * @author UENO Katsuhiro
 * @copyright 2010, Tohoku University.
 *)

infix 4 = <> > >= < <=
val op < = SMLSharp_Builtin.Int32.lt

structure Pointer =
struct

  val advance = SMLSharp_Builtin.Pointer.advance
  val load = SMLSharp_Builtin.Pointer.deref
  val store = SMLSharp_Builtin.Pointer.store

  fun isNull (ptr : 'a ptr) =
      SMLSharp_Builtin.Pointer.toUnitPtr ptr = _NULL

  fun NULL () = SMLSharp_Builtin.Pointer.fromUnitPtr _NULL

  val prim_import =
      _import "prim_UnmanagedMemory_import"
      : __attribute__((unsafe,fast,gc))
        (unit ptr, int) -> SMLSharp_Builtin.Word8.word vector

  fun importBytes (ptr : SMLSharp_Builtin.Word8.word ptr, len) =
      if len < 0 then raise Size
      else prim_import (SMLSharp_Builtin.Pointer.toUnitPtr ptr, len)

  val importString =
      _import "sml_str_new"
      : __attribute__((unsafe,fast,gc))
        char ptr -> string

end
