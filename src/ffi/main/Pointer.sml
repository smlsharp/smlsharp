(**
 * pointer operations
 * @author UENO Katsuhiro
 * @copyright (C) 2021 SML# Development Team.
 *)

infix 4 = <> > >= < <=
val op < = SMLSharp_Builtin.Int32.lt

structure Pointer =
struct

  val advance = SMLSharp_Builtin.Pointer.advance
  val load = SMLSharp_Builtin.Pointer.deref
  val store = SMLSharp_Builtin.Pointer.store

  fun isNull (ptr : 'a ptr) =
      SMLSharp_Builtin.Pointer.toUnitPtr ptr = SMLSharp_Builtin.Pointer.null ()

  val NULL = SMLSharp_Builtin.Pointer.null

  val prim_import =
      _import "prim_UnmanagedMemory_import"
      : __attribute__((unsafe,fast,gc))
        (unit ptr, int) -> word8 vector

  fun importBytes (ptr : word8 ptr, len) =
      if len < 0 then raise Size
      else prim_import (SMLSharp_Builtin.Pointer.toUnitPtr ptr, len)

  val importString =
      _import "sml_str_new"
      : __attribute__((unsafe,fast,gc))
        char ptr -> string

  val str_new2 =
      _import "sml_str_new2"
      : __attribute__((unsafe,fast,gc))
        (char ptr, word) -> string

  fun importString' (ptr, len) =
      if len < 0 then raise Size
      else str_new2 (ptr, SMLSharp_Builtin.Word32.fromInt32 len)

end
