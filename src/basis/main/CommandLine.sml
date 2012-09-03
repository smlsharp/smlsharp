(**
 * CommandLine structure.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @copyright 2010, 2011, Tohoku University.
 *)
_interface "CommandLine.smi"
infix 6 -
infixr 5 ::
infix 4 >
val op - = SMLSharp.Int.sub
val op > = SMLSharp.Int.gt

structure CommandLine :> COMMAND_LINE =
struct

  val prim_argc =
      _import "prim_CommandLine_argc"
      : __attribute__((no_callback)) unit -> int
  val prim_argv =
      _import "prim_CommandLine_argv"
      : __attribute__((no_callback)) unit -> char ptr ptr
  val sml_str_new =
      _import "sml_str_new"
      : __attribute__((no_callback,alloc)) char ptr -> string

  fun name () =
      let
        val argc = prim_argc ()
        val argv = prim_argv ()
      in
        if argc > 0
        then sml_str_new (SMLSharp.Pointer.deref_ptr argv)
        else ""
      end

  fun arguments () =
      let
        val argc = prim_argc ()
        val argv = prim_argv ()
        fun loop (i, l) =
            if i > 1
            then let val p = SMLSharp.Pointer.advance (argv, i - 1)
                     val s = sml_str_new (SMLSharp.Pointer.deref_ptr p)
                 in loop (i - 1, s :: l)
                 end
            else l
      in
        loop (argc, nil)
      end

end
