structure SignalHandler =
struct

  val signum_SIGHUP = 0w1
  val signum_SIGINT = 0w2
  val signum_SIGPIPE = 0w13
  val signum_SIGALRM = 0w14
  val signum_SIGTERM = 0w15

  val sml_signal_check =
      _import "sml_signal_check"
      : __attribute__((fast)) () -> word
  val sml_signal_sigaction =
      _import "sml_signal_sigaction"
      : __attribute__((fast)) (() -> ()) -> int

  datatype signal =
      SIGINT
    | SIGHUP
    | SIGPIPE
    | SIGALRM
    | SIGTERM

  val signals =
      [(SIGINT, signum_SIGINT),
       (SIGHUP, signum_SIGHUP),
       (SIGPIPE, signum_SIGPIPE),
       (SIGALRM, signum_SIGALRM),
       (SIGTERM, signum_SIGTERM)]

  exception Signal of signal list

  val ignoreSignal = ref false

  fun handler () : unit =
      if !ignoreSignal then () else
      let
        val sigset = sml_signal_check ()
        val signums =
            List.mapPartial
              (fn (signame, signum) =>
                  if Word.andb (sigset, Word.<< (0w1, signum)) <> 0w0
                  then SOME signame else NONE)
              signals
      in
        raise Signal signums
      end

  fun init () =
      if sml_signal_sigaction handler <> 0
      then raise SMLSharp_Runtime.OS_SysErr ()
      else ()

  fun stop () = ignoreSignal := true

end
