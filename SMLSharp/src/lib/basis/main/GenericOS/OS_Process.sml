(* os-process.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 * The Posix-based implementation of the generic process control
 * interface (OS.Process).
 *
 *)
structure OS_Process : OS_PROCESS =
struct

  (***************************************************************************)

  type status = int

  (***************************************************************************)

  val success = 0
  val failure = 1

  fun isSuccess 0 = true
    | isSuccess _ = false

  fun system cmd = SMLSharp.Runtime.GenericOS_system cmd

  local
    val finalizersRef = ref ([] : (unit -> unit) list)
  in
  fun atExit finalizer = finalizersRef := finalizer :: (!finalizersRef);

  fun terminate x = (SMLSharp.Runtime.GenericOS_exit x; raise Fail "not terminated.")
  fun exit sts =
      let
        (*
         * The SML Basis specification says about exit:
         * 1) An exception raised in a finalizer should be trapped and ignored.
         * 2) Calls to exit from finalizers do not return, but should cause
         *   the remainder of the finalizers to be executed.
         *)
        fun invokeFinalizers () =
            case !finalizersRef of
              finalizer :: finalizers =>
              (
                (* Even if a finalizer calls exit, each finalizer should
                 * not be invoked more than once. *)
                finalizersRef := finalizers;
                finalizer () handle _ => ();
                invokeFinalizers ()
              )
            | [] => ()
      (* ToDo : flushes and close all I/O streams opened using the Library. *)
      in
        invokeFinalizers ();
        CleanUp.clean CleanUp.AtExit;
        terminate sts
      end
  end

  fun getEnv name = SMLSharp.Runtime.GenericOS_getEnv name

  fun sleep time =
      let val seconds = Time.toSeconds time
      in
        if LargeInt.sign seconds < 0
        then ()
        else SMLSharp.Runtime.GenericOS_sleep (Word.fromLargeInt seconds)
      end

  (***************************************************************************)

end
