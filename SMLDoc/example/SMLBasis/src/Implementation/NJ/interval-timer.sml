(* interval-timer.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 * An interface to system interval timers.
 *
 *)

local
    structure Int = IntImp
    structure Int32 = Int32Imp
in
structure IntervalTimer : INTERVAL_TIMER =
  struct

    fun cfun x = CInterface.c_function "SMLNJ-RunT" x

    val tick' : unit -> (Int32.int * int) = cfun "intervalTick"
    val setITimer : (Int32.int * int) option -> unit = cfun "setIntTimer"

    fun tick () = let val (s, us) = tick'()
	  in
	    TimeImp.fromMicroseconds
		(Int32.toLarge s * 1000000 + Int.toLarge us)
	  end

    fun fromTimeOpt NONE = NONE
      | fromTimeOpt (SOME t) = let
	    val usec = TimeImp.toMicroseconds t
	    val (sec, usec) = IntInfImp.divMod (usec, 1000000)
	in
	    SOME (Int32.fromLarge sec, Int.fromLarge usec)
	end

    fun setIntTimer timOpt = setITimer(fromTimeOpt timOpt)

  end
end


