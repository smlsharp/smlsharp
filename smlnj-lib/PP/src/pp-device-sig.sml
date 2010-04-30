(* pp-device-sig.sml
 *
 * COPYRIGHT (c) 1997 Bell Labs, Lucent Technologies.
 *
 * A pretty-printer device is an abstraction of an output stream.
 *)

signature PP_DEVICE =
  sig
    type device
	(* a device is an abstraction of an output stream. *)

    type style
	(* an abstraction of font and color information.  A device keeps a stack
	 * of styles, with the top of stack being the "current" style.
	 * Implementers of this signature should extend it with functions for
	 * creating style values.
	 *)

    val sameStyle : (style * style) -> bool
	(* are two styles the same? *)

    val pushStyle : (device * style) -> unit
    val popStyle  : device -> unit
	(* push/pop a style from the devices style stack.  A pop on an
	 * empty style stack is a nop.
	 *)
 
    val defaultStyle : device -> style
	(* the default style for the device (this is the current style,
	 * if the style stack is empty).
	 *)

    val depth : device -> int option
	(* maximum printing depth (in terms of boxes) *)
    val lineWidth : device -> int option
	(* the width of the device *)
    val textWidth : device -> int option
	(* the suggested maximum width of text on a line *)

    val space : (device * int) -> unit
	(* output some number of spaces to the device *)

    val newline : device -> unit
	(* output a new-line to the device *)

    val string : (device * string) -> unit
    val char : (device * char) -> unit
	(* output a string/character in the current style to the device *)

    val flush : device -> unit
	(* if the device is buffered, then flush any buffered output *)

  end;

