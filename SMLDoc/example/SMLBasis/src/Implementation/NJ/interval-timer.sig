(* interval-timer.sig
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 * An interface to system interval timers.
 *
 *)

signature INTERVAL_TIMER =
  sig

    val tick : unit -> Time.time
	(* the minimum interval that the interval timers support *)

    val setIntTimer : Time.time option -> unit
	(* set the interval timer; NONE means to disable the timer. *)

  end;

