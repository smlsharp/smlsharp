(**
 * Integer related structures.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @copyright 2010, 2011, Tohoku University.
 *)
_interface "SMLSharpOSProcess.smi"

structure SMLSharpOSProcess : OS_PROCESS =
struct

infix 7 * / div mod
infix 6 + -
infixr 5 ::
infix 4 = <> > >= < <=
infix 3 :=

  val prim_exit =
      _import "prim_GenericOS_exit"
      : __attribute__((no_callback)) int -> unit
  val prim_getenv =
      _import "getenv"
      : __attribute__((no_callback)) string -> char ptr
  val prim_sleep =
      _import "sleep"
      : __attribute__((no_callback)) word -> word
  val prim_system =
      _import "system"
      : __attribute__((no_callback)) string -> int

  type status = int
  val success = 0 : status
  val failure = 1 : status
  fun isSuccess x = x = success

  fun system cmd =
      let
        val status = prim_system cmd
      in
        if SMLSharp.Int.lt (status, 0)
        then raise SMLSharpRuntime.OS_SysErr ()
        else status
      end

  datatype atExitState =
      EXIT of exn
    | ATEXIT of (unit -> unit) list

  val atExitStateRef = ref (ATEXIT nil)

  fun atExit finalizer =
      case atExitStateRef of
        ref (EXIT _) => ()
      | ref (ATEXIT finalizers) =>
        atExitStateRef := ATEXIT (finalizer::finalizers)

  fun exit status =
      case atExitStateRef of
        ref (EXIT exn) => raise exn
      | ref (ATEXIT finalizers) =>
        let
          exception Exit
          val _ = atExitStateRef := EXIT Exit
          fun loop nil = ()
            | loop (h::t) = (h () handle _ => (); loop t)
        in
          (* ToDo : flushes and close all I/O streams opened using the
           * Library. *)
          loop finalizers;
          SMLSharpSMLNJ_CleanUp.clean SMLSharpSMLNJ_CleanUp.AtExit;
          prim_exit status;
          raise Fail "OS.Process.exit"
        end

  fun terminate status =
      (prim_exit status; raise Fail "OS.Process.terminate")

  fun getEnv name =
      SMLSharpRuntime.str_new_option (prim_getenv name)

  fun sleep time =
      let
        val seconds = Time.toSeconds time
      in
        if SMLSharp.Int.lteq (LargeInt.sign seconds, 0)
        then ()
        else (prim_sleep (Word.fromLargeInt seconds); ())
      end

end
