(**
 * pointer operations
 * @author UENO Katsuhiro
 * @copyright 2010, Tohoku University.
 *)

local
  infix 6 + -
  infix 4 = <> > >= < <=
  val op + = SMLSharp.Int.add
  val op < = SMLSharp.Int.lt
in

structure Pointer =
struct

  val advance = SMLSharp.Pointer.advance

  fun isNull (ptr : 'a ptr) =
      SMLSharp.Pointer.toUnitPtr ptr = _NULL

  fun NULL () = SMLSharp.Pointer.fromUnitPtr _NULL

(*
  fun sub (ptr, n) = !! (advance (ptr, n))

  fun update (ptr, n, v) = store (advance (ptr, n), v)
*)

  val prim_import =
      _import "prim_UnmanagedMemory_import"
      : __attribute__((no_callback,alloc))
        (unit ptr, int) -> string
  val prim_size =
      _import "prim_UnmanagedString_size"
      : __attribute__((no_callback))
        unit ptr -> int

  fun importBytes (ptr : Word8.word ptr, len) : Word8Vector.vector =
      if len < 0 then raise Size
      else prim_import (SMLSharp.Pointer.toUnitPtr ptr, len)

  fun importString (ptr : char ptr) =
      let
        val ptr = SMLSharp.Pointer.toUnitPtr ptr
      in
        (* + 1 is for sentinel "\0" character *)
        prim_import (ptr, prim_size ptr + 1)
      end

end

end (* local *)
