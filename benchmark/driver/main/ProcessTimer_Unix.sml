(**
 * ProcessTimer for platforms on which Posix structure is available.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ProcessTimer_Unix.sml,v 1.4 2007/12/03 01:22:37 kiyoshiy Exp $
 *)
structure ProcessTimer : PROCESS_TIMER =
struct

  (***************************************************************************)

  type timer =
       {
         elapsed:Time.time,
         stime:Time.time,
         utime:Time.time,
         cstime:Time.time,
         cutime:Time.time
       }

  (***************************************************************************)

  val createTimer = Posix.ProcEnv.times

  fun getTime times1 =
      let
        val times2 = Posix.ProcEnv.times ()
        fun diffTime selector1 selector2 =
            Time.+
            (
              Time.-(selector1 times2, selector1 times1),
              Time.-(selector2 times2 ,selector2 times1)
            )
            handle General.Overflow => Time.zeroTime
      in
        {
          sys = diffTime #stime #cstime, 
          usr = diffTime #utime #cutime,
          real = Time.-(#elapsed times2, #elapsed times1)
                 handle General.Overflow => Time.zeroTime
        }
      end
      handle General.Overflow => 
             {sys = Time.zeroTime, usr = Time.zeroTime, real = Time.zeroTime}

  (***************************************************************************)

end;
