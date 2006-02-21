(**
 * Timer structure.
 * @author AT&T Bell Laboratories.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Timer.sml,v 1.2 2005/09/09 11:41:45 kiyoshiy Exp $
 *)
(* internal-timer.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 *)
structure Timer
          : sig

              include TIMER
              val resetTimers : unit -> unit

end = 
struct

  (***************************************************************************)

  type time = { usr: Time.time, sys: Time.time }

  datatype cpu_timer = CPUT of { nongc: time, gc: time }
  datatype real_timer = RealT of Time.time

  (***************************************************************************)

  local
    val gettime' :
        int -> (Int32.int * int * Int32.int * int * Int32.int * int) =
        Timer_getTime
(*
    fun mkTime (s, us) =
        Time.fromMicroseconds (1000000 * Int32.toLarge s + Int.toLarge us)
*)
    fun mkTime (s, us) =
        Time.fromSecondsAndMicroSeconds (Int.toLarge s, Int.toLarge us)
  in
  fun getTime () =
      let
        val (ts, tu, ss, su, gs, gu) = gettime' 0
      in
        {
          nongc = {usr = mkTime (ts, tu), sys = mkTime (ss, su)},
          gc = {usr = mkTime (gs, gu), sys = Time.zeroTime}
        }
    end
  end (* local *)

  fun startCPUTimer () = CPUT (getTime())
  fun startRealTimer () = RealT (Time.now ())

  local
    val initCPUTime = ref (startCPUTimer ())
    val initRealTime = ref (startRealTimer ())
  in
  fun totalCPUTimer () = !initCPUTime
  fun totalRealTimer () = !initRealTime
  fun resetTimers () =
      (
        initCPUTime := startCPUTimer ();
        initRealTime := startRealTimer ()
      )
  end (* local *)

  local
    infix -- ++
    fun usop timeop (t: time, t': time) =
        {usr = timeop (#usr t, #usr t'), sys = timeop (#sys t, #sys t')}
    val op -- = usop Time.-
    val op ++ = usop Time.+
  in

  fun checkCPUTimes (CPUT t) =
      let
        val t' = getTime ()
      in
        {nongc = #nongc t' -- #nongc t, gc = #gc t' -- #gc t}
      end

  fun checkCPUTimer tmr =
      let
        val t = checkCPUTimes tmr
      in
        #nongc t ++ #gc t
      end
        
  fun checkGCTime (CPUT t) = Time.- (#usr (#gc (getTime ())), #usr (#gc t))

  end (* local *)

  fun checkRealTimer (RealT t) = Time.-(Time.now(), t)

  (***************************************************************************)

end
