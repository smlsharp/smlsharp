(* ansi-term.sml
 *
 * COPYRIGHT (c) 2005 John Reppy (http://www.cs.uchicago.edu/~jhr)
 * All rights reserved.
 *
 * Support for ANSI terminal control codes.  Currently, this support
 * is just for display attributes.
 *)

structure ANSITerm : sig

    datatype color
      = Black | Red | Green | Yellow | Blue | Magenta | Cyan | White

    datatype style
      = FG of color	(* foreground color *)
      | BG of color	(* background color *)
      | BF		(* bold/bright *)
      | UL		(* underline *)
      | BLINK
      | REV		(* reverse video *)
      | INVIS		(* invisible *)

  (* return the command string for the given styles; the empty list is "normal" *)
    val toString : style list -> string

  (* output commands to set the given styles; the empty list is "normal" *)
    val setStyle : (TextIO.outstream * style list) -> unit

  end = struct

    datatype color
      = Black | Red | Green | Yellow | Blue | Magenta | Cyan | White

    datatype style
      = FG of color	(* foreground color *)
      | BG of color	(* background color *)
      | BF		(* bold *)
      | UL		(* underline *)
      | BLINK
      | REV		(* reverse video *)
      | INVIS		(* invisible *)

  (* basic color codes *)
    fun colorToCmd Black = 0
      | colorToCmd Red = 1
      | colorToCmd Green = 2
      | colorToCmd Yellow = 3
      | colorToCmd Blue = 4
      | colorToCmd Magenta = 5
      | colorToCmd Cyan = 6
      | colorToCmd White = 7

  (* convert style to integer command *)
    fun styleToCmd (FG c) = 30 + colorToCmd c
      | styleToCmd (BG c) = 40 + colorToCmd c
      | styleToCmd BF = 1
      | styleToCmd UL = 4
      | styleToCmd BLINK = 5
      | styleToCmd REV = 7
      | styleToCmd INVIS = 8

    fun cmdStr [] = ""
      | cmdStr (cmd :: r) = let
	  fun f (cmd, l) = ";" :: Int.toString cmd :: l
	  in
	    concat ("\027[" :: Int.toString cmd :: List.foldr f ["m"] r)
	  end

    fun toString [] = cmdStr[0, 30]
      | toString stys = cmdStr(List.map styleToCmd stys)

    fun setStyle (outStrm, stys) = TextIO.output(outStrm, toString stys)

  end
