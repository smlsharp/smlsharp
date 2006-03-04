(**
 *  Alternative implementation of SignalUtility for platforms where the
 * strucutre Signals is not available.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: SignalUtility_dummy.sml,v 1.5 2006/02/28 16:11:05 kiyoshiy Exp $
 *)
structure SignalUtility =
struct

  (***************************************************************************)

  datatype 'a result = Completed of 'a | Interrupted of string

  val SIGINT = "INT"
  val SIGTERM = "TERM"
  val SIGALRM = "ALRM"

  fun isSupportedSignal signalName = true
  fun doWithHandler signalNames handler f arg = f arg
  fun doWithInterrupt signalNames f arg = Completed(f arg)

  (***************************************************************************)

end
