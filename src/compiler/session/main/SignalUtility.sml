(**
 * Copyright (c) 2006, Tohoku University.
 *
 * utilities for handling signal.
 * @author YAMATODANI Kiyoshi
 * @version $Id: SignalUtility.sml,v 1.10 2006/02/18 04:59:28 ohori Exp $
 *)
structure SignalUtility : SIGNAL_UTILITY =
struct

  (***************************************************************************)

  structure S = Signals

  (***************************************************************************)

  (**
   * This datatype represents the result of computations which might be
   * interrupted.
   *)
  datatype 'a result =
           (** completed *) Completed of 'a
         | (** interrupted by the signal *) Interrupted of string

  datatype action =
           Ignore
         | Default
         | Handle of string -> unit

  (***************************************************************************)

  val SIGINT = "INT"
  val SIGTERM = "TERM"
  val SIGALRM = "ALRM"

  fun isSupportedSignal signalName =
      Option.isSome(Signals.fromString signalName)

  fun signalNameToSignal signalName =
      case Signals.fromString signalName of
        SOME signal => signal
      | NONE => raise Fail ("unknown signal name:" ^ signalName)

  fun setHandler signals handler =
      (
        map
            (fn signal => S.setHandler (signal, handler))
            signals;
        ()
      )

  fun doWithAction signalNames action f arg =
      let
        val signals = map signalNameToSignal signalNames
        (* saves current handler for sigINT *)
        val prevINTHandlers =
            map (fn signal => (signal, S.inqHandler signal)) signals

        (**
         * signal handler
         *
         * @param signal signal
         * @param count the number of times the signal has been signalled
         *      since the last time this 'signalHanlder' was invoked for
         *      this signal.
         * @return a continuation which SML/NJ runtime will invoke.
         * @see Signals.setHandler
         *)
        fun signalHandler handler (signal, count, continuation) =
            (
(*
              print ("signal = " ^ (S.toString signal));
              print (", count = " ^ (Int.toString count) ^ "\n");
*)
              handler (S.toString signal);
              continuation
            )

        val sigAction =
            case action of
              Ignore => S.IGNORE
            | Default => S.DEFAULT
            | Handle handler => S.HANDLER (signalHandler handler)
        val _ = setHandler signals sigAction
        fun cleanUp () = (map S.setHandler prevINTHandlers; ())
      in
        let val result = f arg
        in cleanUp (); result end
        handle exn => (cleanUp (); raise exn)
      end

  (**
   *  This function applies the specified function to the argument.
   * It returns from the function instantly if a signal is raised while the
   * application.
   *
   * @params signalNames f arg
   * @param signalNames list of signal names: "CHLD", "INT", ...
   *      (These are to be passed to Signals.fromString.)
   * @param f a function
   * @param arg an argument to be passed to the 'f'
   * @return Interrupted s, if the execution of 'f arg' has been interrupted by
   *         a signal 's'.
   *         Completed r, if 'f arg' has finished with 'r' as the result.
   *)
  fun doWithInterruption signalNames f arg =
      let
        val signals = map signalNameToSignal signalNames
        (* saves current handler for sigINT *)
        val prevINTHandlers =
            map (fn signal => (signal, S.inqHandler signal)) signals

        (**
         * @params continuation
         * @param continuation a continuation at point of the application of
         * this function. That is, if this continuation is invoked, the
         * execution resumes to codes which follow the application.
         *)
        fun doApply continuation =
            let

              (**
               * wraps the 'continuation' (whose type is 'a cont) into
               * a 'unit cont'.
               *
               * This function creates a continuation which invokes the
               * 'continuation' with the 'value' when invoked.
               *
               * @param value a value to be passed to the 'continuation'
               * @return a 'unit cont' 
               *)
              fun wrapCont value =
                  SMLofNJ.Cont.isolate
                      (fn () => SMLofNJ.Cont.throw continuation value)

              (**
               * signal handler
               *
               *  ML runtime invokes the continuation which this handler
               * returns.
               *  The continuation, then, invokes the 'continuation' with
               * argument
               * NONE, which notifies to the caller of 'catchSignal' that the
               * computation was interrupted.
               *
               * @param signal signal
               * @param count the number of times the signal has been signalled
               *      since the last time this 'signalHanlder' was invoked for
               *      this signal.
               * @return a continuation which SML/NJ runtime will invoke.
               * @see Signals.setHandler
               *)
              fun signalHandler (signal, count, _) =
                  (
(*
                    print ("signal = " ^ (S.toString signal));
                    print (", count = " ^ (Int.toString count) ^ "\n");
*)
                    (* notifies the interruption to the caller of
                     * 'catchSignal' *)
                    wrapCont (Interrupted (Signals.toString signal) )
                  )

              val _ = setHandler signals (S.HANDLER signalHandler)
            in
              (*
               *  executes the application.
               *  This application might be interrupted.
               *  If the application completes without any interruption,
               * 'Completed' is returned.
               *)
              Completed (f arg)
            end
        fun cleanUp () = (map S.setHandler prevINTHandlers; ())
      in
        let val result = SMLofNJ.Cont.callcc doApply
        in cleanUp(); result end
        handle exn => (cleanUp (); raise exn)
      end

  (***************************************************************************)

end;

(*****************************************************************************
     sample code
 *****************************************************************************)
(*
val sleepTime = 5;

fun execute code = 
    let
      fun loop n =
          (
            Posix.Process.sleep (Time.fromSeconds(Int32.fromInt sleepTime));
            if n < (sleepTime * 100)
            then (print ("n = " ^ (Int.toString n) ^ "\n");loop (n + 1))
            else n
          )
    in
        loop 0
    end;

(* sample usage:
fun eval source =
    let
      val code = compile source
      val result = catchSignal execute code
    in
      case result of
        Interrupted signal => (sendKillMessageToChileProcess signal; Failure)
      | Completed result => Success
    end
*)

(* normal case
- SignalUtility.catchSignal [Signals.sigINT] execute [];
n = 0
n = 1
  :
n = 998
n = 999
val it = Completed 1000 : int option
*)

(* interrupted case
- SignalUtility.catchSignal [Signals.sigINT] execute [];
n = 0
n = 1
  :
n = 141
          <-- interrupts by ^C.
n = 141   <-- ??? duplicated
signal = INTcount = 1
val it = Interrupted - : int result
 *)
*)
