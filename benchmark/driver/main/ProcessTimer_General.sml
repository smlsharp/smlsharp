structure ProcessTimer : PROCESS_TIMER =
struct

  (***************************************************************************)

  type timer = Timer.cpu_timer * Timer.real_timer

  (***************************************************************************)

  fun createTimer () = (Timer.startCPUTimer (), Timer.startRealTimer ())

  fun getTime (CPUTimer, realTimer) =
      let
        val {gc, sys, usr} = Timer.checkCPUTimer CPUTimer
        val real = Timer.checkRealTimer realTimer
      in {sys = sys, usr = usr, real = real}
      end

  (***************************************************************************)

end;