structure Timer :> TIMER =
struct
  open Orig_Timer

  val checkCPUTimer =
      fn timer =>
         let val {gc, nongc={sys, usr}} = checkCPUTimes timer
             val {sys=gcsys, usr=gcusr} = gc
             val gc = Orig_Time.+ (gcsys, gcusr)
         in {sys = sys, usr = usr, gc = gc}
         end
end
