structure SignalHandler =
struct

  (* see also src/runtime/signal.c *)
  val FLAG_SIGINT = 0wx1
  val FLAG_SIGHUP = 0wx2
  val FLAG_SIGPIPE = 0wx4
  val FLAG_SIGALRM = 0wx8
  val FLAG_SIGTERM = 0wx16

  val sml_signal_check =
      _import "sml_signal_check"
      : __attribute__((fast)) () -> word
  val sml_signal_sigaction =
      _import "sml_signal_sigaction"
      : __attribute__((fast)) () -> int
  val sml_set_signal_handler =
      _import "sml_set_signal_handler"
      : __attribute__((fast)) (() -> ()) -> int

  datatype signal =
      SIGINT
    | SIGHUP
    | SIGPIPE
    | SIGALRM
    | SIGTERM

  val signals =
      [(SIGINT, FLAG_SIGINT),
       (SIGHUP, FLAG_SIGHUP),
       (SIGPIPE, FLAG_SIGPIPE),
       (SIGALRM, FLAG_SIGALRM),
       (SIGTERM, FLAG_SIGTERM)]

  exception Signal of signal list

  fun handler () : unit =
      let
        val flags = sml_signal_check ()
        val signums =
            List.mapPartial
              (fn (signum, flag) => 
                  if Word.andb (flags, flag) <> 0w0 then SOME signum else NONE)
              signals
      in
        raise Signal signums
      end

  fun init () =
      if sml_signal_sigaction () <> 0
      then raise SMLSharp_Runtime.OS_SysErr ()
      else if sml_set_signal_handler handler <> 0
      then raise OS.SysErr ("sml_set_signal_handler failed", NONE)
      else ()

  fun stop () =
      ignore (sml_set_signal_handler (fn () => ()))

end
