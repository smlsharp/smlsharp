(* pp-stream-sig.sml
 *
 * COPYRIGHT (c) 2005 John Reppy (http://www.cs.uchicago.edu/~jhr)
 * All rights reserved.
 *
 * This interface provides a output stream interface to pretty printing.
 *)

signature PP_STREAM =
  sig
    type device
    type stream

    type token
	(* tokens are an abstraction of strings (allowing for different
	 * widths and style information).
	 *)
    type style

    datatype indent
      = Abs of int		(* indent relative to outer indentation *)
      | Rel of int		(* indent relative to start of box *)

    val openStream  : device -> stream
    val flushStream : stream -> unit
    val closeStream : stream -> unit
    val getDevice   : stream -> device

    val openHBox   : stream -> unit
    val openVBox   : stream -> indent -> unit
    val openHVBox  : stream -> indent -> unit
    val openHOVBox : stream -> indent -> unit
    val openBox    : stream -> indent -> unit
    val closeBox   : stream -> unit

    val token   : stream -> token -> unit
    val string  : stream -> string -> unit

    val pushStyle : (stream * style) -> unit
    val popStyle  : stream -> unit

    val break   : stream -> {nsp : int, offset : int} -> unit
    val space   : stream -> int -> unit
	(* space n == break{nsp=n, offset=0} *)
    val cut     : stream -> unit
	(* cut == break{nsp=0, offset=0} *)
    val newline : stream -> unit
    val nbSpace : stream -> int -> unit
	(* emits a nonbreakable space *)

    val control : stream -> (device -> unit) -> unit

  end

