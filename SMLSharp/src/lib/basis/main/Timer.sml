(**
 * Timer structure.
 * @author AT&T Bell Laboratories.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Timer.sml,v 1.4 2007/07/24 15:06:05 kiyoshiy Exp $
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

  fun timeToString {usr, sys} =
      "{usr = " ^ Time.fmt 10 usr ^ ", sys = " ^ Time.fmt 10 sys ^ "}"
  fun cpu_timerToString {nongc, gc} =
      "{nongc = " ^ timeToString nongc ^ ", gc = " ^ timeToString gc ^ "}"

  local
    val gettime' :
        int -> (Int32.int * int * Int32.int * int * Int32.int * int) =
        SMLSharp.Runtime.Timer_getTime
(*
    fun mkTime (s, us) =
        Time.fromMicroseconds (1000000 * Int32.toLarge s + Int.toLarge us)
*)
    fun mkTime (s, us) =
        Time.fromSecondsAndMicroSeconds (Int.toLarge s, Int.toLarge us)
  in
  fun getTime () =
      let
        val (ss, su, us, uu, gs, gu) = gettime' 0
        val nongc_usr = mkTime (us, uu)
        val nongc_sys = mkTime (ss, su)
        val gc_usr = mkTime (gs, gu)
(*
val _ = print ("ss = " ^ Int.toString ss ^ "\n")
val _ = print ("su = " ^ Int.toString su ^ "\n")
val _ = print ("us = " ^ Int.toString us ^ "\n")
val _ = print ("uu = " ^ Int.toString uu ^ "\n")
val _ = print ("nongc_usr = " ^ LargeInt.toString (Time.toMicroseconds nongc_usr) ^ "\n")
val _ = print ("nongc_usr(sec) = " ^ LargeInt.toString (Time.toSeconds nongc_usr) ^ "\n")
val _ = print ("nongc_sys = " ^ LargeInt.toString (Time.toMicroseconds nongc_sys) ^ "\n")
val _ = print ("nongc_sys(sec) = " ^ LargeInt.toString (Time.toSeconds nongc_sys) ^ "\n")
*)
      in
        {
          nongc = {usr = nongc_usr, sys = nongc_sys},
          gc = {usr = gc_usr, sys = Time.zeroTime}
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
(*
val _ = print ("t = " ^ cpu_timerToString t ^ "\n")
val _ = print ("t' = " ^ cpu_timerToString t' ^ "\n")
*)
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
