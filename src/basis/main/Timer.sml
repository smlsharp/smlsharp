(**
 * Timer
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @copyright 2013, Tohoku University.
 *)

infix 6 + - ^
infix 4 = <> > >= < <=
val op - = SMLSharp_Builtin.Int.sub_unsafe
structure Array = SMLSharp_Builtin.Array

structure Timer =
struct

  val prim_getTimes =
      _import "prim_Timer_getTimes"
      : __attribute__((no_callback)) int array -> int

  fun getTimes () =
      let
        val buf = Array.alloc 6
        val err = prim_getTimes buf
      in
        if err = 0 then () else raise SMLSharp_Runtime.OS_SysErr ();
        {sys = {sec = Array.sub_unsafe (buf, 0),
                usec = Array.sub_unsafe (buf, 1)},
         usr = {sec = Array.sub_unsafe (buf, 2),
                usec = Array.sub_unsafe (buf, 3)},
         gc = {sec = Array.sub_unsafe (buf, 4),
               usec = Array.sub_unsafe (buf, 5)}}
      end

  type time = {sec : int, usec : int}
  type cpu_timer = {sys : time, usr : time, gc : time}
  type real_timer = Time.time

  fun toTime ({sec, usec}:time) =
      Time.+ (Time.fromSeconds (IntInf.fromInt sec),
              Time.fromMicroseconds (IntInf.fromInt usec))

  fun difTime ({sec=sec1, usec=usec1}:time, {sec=sec2, usec=usec2}:time) =
      {sec = sec1 - sec2, usec = usec1 - usec2} : time

  fun difTimer ({sys=sys1, usr=usr1, gc=gc1}:cpu_timer,
                {sys=sys2, usr=usr2, gc=gc2}:cpu_timer) =
      {sys = difTime (sys1, sys2),
       usr = difTime (usr1, usr2),
       gc = difTime (gc1, gc2)} : cpu_timer

  val startCPUTimer = getTimes

  fun checkCPUTimes t =
      let
        val {sys, usr, gc} = difTimer (getTimes (), t)
      in
        {nongc = {sys = toTime sys, usr = toTime usr},
         gc = {sys = Time.zeroTime, usr = toTime gc}}
      end

  fun checkCPUTimer t =
      let
        val {sys, usr, gc} = difTimer (getTimes (), t)
      in
        {sys = toTime sys, usr = Time.+ (toTime usr, toTime gc)}
      end

  fun checkGCTime ({gc, ...}:cpu_timer) =
      toTime (difTime (#gc (getTimes ()), gc))

  val initCPUTime = getTimes ()
  fun totalCPUTimer () = difTimer (getTimes (), initCPUTime)

  fun startRealTimer () = Time.now ()

  fun checkRealTimer t = Time.- (Time.now (), t)

  val initRealTime = Time.now ()
  fun totalRealTimer () = Time.- (Time.now (), initRealTime)

end
