(* controls-sig.sml
 *
 * COPYRIGHT (c) 2002 Bell Labs, Lucent Technologies
 *)

signature CONTROLS =
  sig

    type priority = int list
    type 'a control

  (* a converter for control values *)
    type 'a value_cvt = {
	tyName : string,
	fromString : string -> 'a option,
	toString : 'a -> string
      }

  (* create a new control *)
    val control : {
	    name : string,	(* name of the control *)
	    pri : priority,	(* control's priority *)
            obscurity : int,	(* control's detail level; higher means *)
				(* more obscure *)
	    help : string,	(* control's description *)
	    ctl : 'a ref	(* ref cell holding control's state *)
	  } -> 'a control

  (* generate a control *)
    val genControl : {
	    name : string,
	    pri : priority,
            obscurity : int,
	    help : string,
	    default : 'a
	  } -> 'a control

  (* this exception is raised to communicate that there is a syntax error
   * in a string representation of a control value.
   *)
    exception ValueSyntax of {tyName : string, ctlName : string, value : string}

  (* create a string control from a typed control *)
    val stringControl : 'a value_cvt -> 'a control -> string control

  (* control operations *)
    val name : 'a control -> string
    val get : 'a control -> 'a
    val set : 'a control * 'a -> unit
    val set' : 'a control * 'a -> unit -> unit (* delayed,
						* error checking in 1st stage *)
    val info : 'a control -> {priority : priority, obscurity : int, help : string}

  (* capture current value (1st stage) and restore it (2nd stage) *)
    val save'restore : 'a control -> unit -> unit

  (* compare the priority of two controls *)
    val compare : ('a control * 'a control) -> order

  end
