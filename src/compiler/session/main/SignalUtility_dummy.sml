(**
 * Copyright (c) 2006, Tohoku University.
 *
 *  Alternative implementation of SignalUtility for platforms where the
 * strucutre Signals is not available.
 * @author YAMATODANI Kiyoshi
 * @version $Id: SignalUtility_dummy.sml,v 1.4 2006/02/18 04:59:28 ohori Exp $
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
