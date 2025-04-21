(**
 * SMLSharp_OSProcess
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @copyright (C) 2021 SML# Development Team.
 *)

infix 7 * / div mod
infix 6 + -
infixr 5 ::
infix 4 = <> > >= < <=
infix 3 :=
val ! = SMLSharp_Builtin.General.!
val op := = SMLSharp_Builtin.General.:=

structure SMLSharp_OSProcess =
struct

  val prim_exit =
      _import "prim_GenericOS_exit"
      : int -> ()
  val prim_getenv =
      _import "getenv"
      : string -> char ptr
  val prim_sleep =
      _import "sleep"
      : word -> word
  val prim_system =
      _import "prim_GenericOS_system"
      : string -> int

  type status = int
  val success = 0 : status
  val failure = 1 : status
  fun isSuccess x = x = success

  fun system cmd =
      let
        val status = prim_system cmd
      in
        if SMLSharp_Builtin.Int32.lt (status, 0)
        then raise SMLSharp_Runtime.OS_SysErr ()
        else status
      end

  fun terminate status =
      (prim_exit status;
       raise SMLSharp_Runtime.Bug "OS.Process.terminate")

  fun getEnv name =
      SMLSharp_Runtime.str_new_option (prim_getenv name)

  fun sleep time =
      let
        val seconds = Time.toSeconds time
      in
        if SMLSharp_Builtin.Int32.lteq (IntInf.sign seconds, 0)
        then ()
        else (prim_sleep (Word32.fromLargeInt seconds); ())
      end

  datatype exitState = RUN | EXIT
  val exitState = ref RUN
  type atexit_tag = (unit -> unit) ref
  val cleanups = ref nil : atexit_tag list ref

  exception ExitAtCleanup

  fun exit status =
      case !exitState of
        EXIT => raise ExitAtCleanup
      | RUN =>
        let
          fun loop nil = ()
            | loop (h::t) = (!h () handle _ => (); loop t)
          val actions = !cleanups
        in
          exitState := RUN;
          cleanups := nil;
          loop actions;
          terminate status
        end

  fun atExit action =
      case !exitState of
        EXIT => ()
      | RUN => cleanups := ref action :: !cleanups

  fun atExit' action =
      let
        val tag = ref action
      in
        cleanups := tag :: !cleanups;
        tag
      end

  fun cancelAtExit tag =
      let
        fun rev (nil : atexit_tag list, r) = r
          | rev (h::t, r) = rev (t, h::r)
        fun filter (_, nil : atexit_tag list) =
            raise SMLSharp_Runtime.Bug "cancelAtExit: tag not found"
          | filter (l, h::t) = if h = tag then rev (l, t) else filter (h::l, t)
      in
        cleanups := filter (nil, !cleanups)
      end

  fun rebindAtExit (tag : atexit_tag, action) = tag := action

end
