(* time-limit.sml
 *
 * COPYRIGHT (c) 1993 by AT&T Bell Laboratories.  See COPYRIGHT file for details.
 *)

structure TimeLimit : sig
    exception TimeOut
    val timeLimit : Time.time -> ('a -> 'b) -> 'a -> 'b
  end = struct

    exception TimeOut

    fun timeLimit t f x = let
	  val setitimer = SMLofNJ.IntervalTimer.setIntTimer
	  fun timerOn () = ignore(setitimer (SOME t))
	  fun timerOff () = ignore(setitimer NONE)
	  val escapeCont = SMLofNJ.Cont.callcc (fn k => (
		SMLofNJ.Cont.callcc (fn k' => (SMLofNJ.Cont.throw k k'));
		timerOff();
		raise TimeOut))
	  fun handler _ = escapeCont
	  in
	    Signals.setHandler (Signals.sigALRM, Signals.HANDLER handler);
	    timerOn();
	    ((f x) handle ex => (timerOff(); raise ex))
	      before timerOff()
	  end

  end; (* TimeLimit *)
