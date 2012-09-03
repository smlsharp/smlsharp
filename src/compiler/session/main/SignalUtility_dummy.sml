(**
 *  Alternative implementation of SignalUtility for platforms where the
 * strucutre Signals is not available.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: SignalUtility_dummy.sml,v 1.6 2006/11/04 15:33:11 kiyoshiy Exp $
 *)
structure SignalUtility : SIGNAL_UTILITY =
struct

  (***************************************************************************)

  datatype 'a result = Completed of 'a | Interrupted of string

  datatype action =
           Ignore
         | Default
         | Handle of string -> unit

  val SIGINT = "INT"
  val SIGTERM = "TERM"
  val SIGALRM = "ALRM"

  fun isSupportedSignal signalName = true
  fun doWithAction signalNames action f arg = f arg
  fun doWithInterruption signalNames f arg = Completed(f arg)

  (***************************************************************************)

end
