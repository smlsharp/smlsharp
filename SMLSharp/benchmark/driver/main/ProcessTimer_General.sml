(**
 * ProcessTimer for platforms on which Posix structure is not available.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ProcessTimer_General.sml,v 1.4 2007/12/03 01:22:37 kiyoshiy Exp $
 *)
structure ProcessTimer : PROCESS_TIMER =
struct

  (***************************************************************************)

  type timer = Timer.cpu_timer * Timer.real_timer

  (***************************************************************************)

  fun createTimer () = (Timer.startCPUTimer (), Timer.startRealTimer ())

  fun getTime (CPUTimer, realTimer) =
      let
        val {sys, usr} = Timer.checkCPUTimer CPUTimer
        val real = Timer.checkRealTimer realTimer
      in {sys = sys, usr = usr, real = real}
      end

  (***************************************************************************)

end;