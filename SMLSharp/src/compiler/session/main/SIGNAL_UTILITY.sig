(**
 * utilities for handling signal.
 * @author YAMATODANI Kiyoshi
 * @version $Id: SIGNAL_UTILITY.sig,v 1.6 2005/06/15 06:37:37 kiyoshiy Exp $
 *)
signature SIGNAL_UTILITY =
sig

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

  (** name of SIGINT *)
  val SIGINT : string
  (** name of SIGTERM *)
  val SIGTERM : string
  (** name of SIGALRM *)
  val SIGALRM : string

  (**
   * indicates whether the signal can be handled by the SignalUtility.
   * @params name
   * @param name signal name
   * @return true if the signal denoted by the name can be handled.
   *)
  val isSupportedSignal : string -> bool

  (**
   *  create a function in which execution raised signals are caught by a
   * handler.
   * @params signalNames handler function argument
   * @param signalNames a list of names of signals to be caught by the handler.
   * @param handler a function which will be invoked when a signal is received.
   *         The name of the caught signal is passed as an argument.
   * @param function the function to be invoked. Signals received in the
   *       invocation of this function are caught by the handler.
   * @param argument the argument to the function.
   * @return return value of an application of the function to the argument.
   *)
  val doWithAction :
      string list -> action -> ('a -> 'b) -> 'a -> 'b

  (**
   *  create a function which returns if a signal is received in its execution.
   * @params signalNames function argument
   * @param signalNames a list of names of signals to be detected.
   * @param function the function to be invoked. If a signal is received in the
   *       invocation of this function, Interrupted is returned.
   * @param argument the argument to the function.
   * @return return Completed, if no signal is received in the invocation of
   *      the function. Interrupted, if any signal is received.
   *)
  val doWithInterruption : string list -> ('a -> 'b) -> 'a -> 'b result

  (***************************************************************************)

end;
