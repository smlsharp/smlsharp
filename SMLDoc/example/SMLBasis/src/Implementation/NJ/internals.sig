(* internals.sig
 *
 * COPYRIGHT (c) 1996 AT&T Research.
 *
 * This structure (SMLofNJ.Internals) is a gathering place for internal
 * features that need to be exposed outside the boot directory.
 *)

signature INTERNALS =
  sig

    structure CleanUp : CLEAN_UP
    structure ProfControl : PROF_CONTROL
    structure GC : GC

    val prHook : (string -> unit) ref
	(* this hook can be used to change the top-level print function *)

  (* Routines for managing the internal signal handler tables.  These are
   * for programs that must otherwise bypass the standard initialization
   * mechanisms.
   *)
    val initSigTbl : unit -> unit
    val clearSigTbl : unit -> unit
    val resetSigTbl : unit -> unit

  (* reset the total real and CPU time timers *)
    val resetTimers : unit -> unit

  (* back-tracing control (experimental; M.Blume, 06/2000) *)
    structure BTrace : sig
	val install : { corefns: { save: unit -> unit -> unit,
				   push: int * int -> unit -> unit,
				   nopush: int * int -> unit,
				   add: int * int -> unit,
				   reserve: int -> int,
				   register: int * int * string -> unit,
				   report: unit -> unit -> string list },
			reset: unit -> unit,
			mode: bool option -> bool }
		      -> unit
	val mode : bool option -> bool
	val report : unit -> unit -> string list
	val bthandle : { work : unit -> 'a,
			 hdl : exn * string list -> 'a } -> 'a
	(* The following is needed in evalloop.sml (or any other module
	 * that explicitly handles the BTrace exception but hasn't itself
	 * been compiled with mode=true) to make sure that the call
	 * history is being unwound correctly. *)
	val save : unit -> unit -> unit
	(* Trigger an explicit back-trace.  The result will be reported
	 * IN FULL by bthandle; intervening handlers and re-raisers are
	 * completely ignored. *)
	val trigger : unit -> 'a
    end

  end;
