(* parser-sig.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *)

signature REGEXP_PARSER =
  sig

    (** read an external representation of a regular expression
     * from the stream and return an abstract syntax representation
     *)
(*
    val scan : (MBChar.char, 'a) StringCvt.reader
	          -> (RegExpSyntax.syntax, 'a) StringCvt.reader
*)
    val scan : (RegExpSyntax.syntax, 'strm) MBParserCombinator.parser

  end

