_interface "internal-timer.smi"
infix 7 *
infix 6 +
infix 4 =
val op + = LargeInt.+
val op * = LargeInt.*
structure CInterface =
struct
  val getTimes =
      _import "prim_Timer_getTimes"
      : __attribute__((no_callback)) int array -> int
  fun c_function (_:string) (_:string) () =
      let
        val buf = SMLSharp.PrimArray.allocArray 6
        val err = getTimes buf
      in
        if err = 0 then () else raise SMLSharpRuntime.OS_SysErr ();
        (SMLSharp.PrimArray.sub (buf, 0),  (* sys sec *)
         SMLSharp.PrimArray.sub (buf, 1),  (* sys msec *)
         SMLSharp.PrimArray.sub (buf, 2),  (* usr sec *)
         SMLSharp.PrimArray.sub (buf, 3),  (* usr msec *)
         SMLSharp.PrimArray.sub (buf, 4),  (* gc sec *)
         SMLSharp.PrimArray.sub (buf, 5))  (* gc msec *)
      end
end
structure PreBasis =
struct
  type time = Time.time
end
structure IntImp = Int
structure Int32Imp = Int
structure TimeImp = Time
(* internal-timer.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 *)

(*
structure InternalTimer : sig

    include TIMER
    val resetTimers : unit -> unit

end = struct
*)
structure SMLSharpSMLNJ_InternalTimer = struct

    structure PB = PreBasis
    structure Int = IntImp
    structure Int32 = Int32Imp
    structure Time = TimeImp

    type time = { usr: PB.time, sys: PB.time }

    datatype cpu_timer = CPUT of { nongc: time, gc: time }
    datatype real_timer = RealT of PB.time

    local
      val gettime' :
	  unit -> (Int32.int * int * Int32.int * int * Int32.int * int) =
	  CInterface.c_function "SMLNJ-Time" "gettime"

      fun mkTime (s, us) =
(*
	  Time.fromMicroseconds (1000000 * Int32.toLarge s + Int.toLarge us)
*)
	  Time.fromMicroseconds (LargeInt.fromInt 1000000 * Int32.toLarge s + Int.toLarge us)
    in
    fun getTime () = let
	val (ts, tu, ss, su, gs, gu) = gettime' ()
    in
	{ nongc = { usr = mkTime (ts, tu),
		    sys = mkTime (ss, su) },
	  gc = { usr = mkTime (gs, gu),
		 sys = Time.zeroTime } }
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
	(initCPUTime := startCPUTimer ();
	 initRealTime := startRealTimer ())
    end (* local *)

    local
	infix -- ++
	fun usop timeop (t: time, t': time) =
	    { usr = timeop (#usr t, #usr t'), sys = timeop (#sys t, #sys t') }
	val op -- = usop Time.-
	val op ++ = usop Time.+
    in

    fun checkCPUTimes (CPUT t) = let
	val t' = getTime ()
    in
	{ nongc = #nongc t' -- #nongc t, gc = #gc t' -- #gc t }
    end

    fun checkCPUTimer tmr = let
	val t = checkCPUTimes tmr
    in
	#nongc t ++ #gc t
    end

    fun checkGCTime (CPUT t) = Time.- (#usr (#gc (getTime ())), #usr (#gc t))

    end (* local *)

    fun checkRealTimer (RealT t) = Time.-(Time.now(), t)

end (* InternalTimer *)
