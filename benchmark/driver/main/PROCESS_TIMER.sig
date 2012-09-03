(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: PROCESS_TIMER.sig,v 1.3 2007/12/03 01:22:37 kiyoshiy Exp $
 *)
signature PROCESS_TIMER =
sig

  (***************************************************************************)

  type timer

  (***************************************************************************)

  val createTimer : unit -> timer

  val getTime : timer -> BenchmarkTypes.elapsedTime

  (***************************************************************************)

end