(* scan-sig.sml
 *
 * COPYRIGHT (c) 1996 by AT&T Research.  See COPYRIGHT file for details.
 *
 * C-style conversions from string representations.
 *
 * AUTHOR:  John Reppy
 *	    AT&T Research
 *	    jhr@research.att.com
 *)

signature SCAN =
  sig

    datatype fmt_item
      = ATOM of Atom.atom
      | LINT of LargeInt.int
      | INT of Int.int
      | LWORD of LargeWord.word
      | WORD of Word.word
      | WORD8 of Word8.word
      | BOOL of bool
      | CHR of char
      | STR of string
      | REAL of Real.real
      | LREAL of LargeReal.real
      | LEFT of (int * fmt_item)	(* left justify in field of given width *)
      | RIGHT of (int * fmt_item)	(* right justify in field of given width *)

    exception BadFormat			(* bad format string *)

    val sscanf : string -> string -> fmt_item list option
    val scanf  : string -> (char, 'a) StringCvt.reader
	  -> (fmt_item list, 'a) StringCvt.reader

  end (* SCAN *)
