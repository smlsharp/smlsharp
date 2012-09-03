(**
 * Utility functions manipulating abstract syntax tree.
 * @author Copyright 1992 by AT&T Bell Laboratories 
 * @author YAMATODANI Kiyoshi
 * @version $Id: AstUtil.sml,v 1.3 2005/12/03 14:34:25 kiyoshiy Exp $
 *)
structure AstUtil:ASTUTIL =
struct

  (***************************************************************************)

open Ast

val unitPat = RecordPat{def=nil,flexibility=false}
val unitExp = ()
val trueDcon = ["true"]
val falseDcon = ["false"]
val quoteDcon = ["SMLofNJ", "QUOTE"]
val antiquoteDcon = ["SMLofNJ", "ANTIQUOTE"]
val arrowTycon = "->"
val exnID = "exn"
val bogusID = "BOGUS"
val symArg = "<Parameter>"
val itsym = ["it"]

(* layered patterns *)

fun lay3 ((x as VarPat _), y) = LayeredPat{varPat=x,expPat=y}
  | lay3 (ConstraintPat{pattern,constraint}, y) = 
	 (case lay3 (pattern,y)
           of LayeredPat{varPat,expPat} =>
	     LayeredPat{varPat=varPat,
			expPat=ConstraintPat{pattern=expPat,
					     constraint=constraint}}
            | pat => pat)
  | lay3 (MarkPat(x,_),y) = lay3 (x,y)
  | lay3 (FlatAppPat[x],y) = y
  | lay3 (x,y) = y

fun lay2 (ConstraintPat{pattern,constraint}, y) = 
	 (case lay2 (pattern,y)
           of LayeredPat{varPat,expPat} =>
	     LayeredPat{varPat=varPat,
			expPat=ConstraintPat{pattern=expPat,
					     constraint=constraint}}
            | pat => pat)
  | lay2 (MarkPat(x,_),y) = lay2 (x,y)
  | lay2 (FlatAppPat[item],y) = lay3(item,y)
  | lay2 p = lay3 p

fun lay (ConstraintPat{pattern,constraint}, y) = 
         (case lay2 (pattern,y)
           of LayeredPat{varPat,expPat} =>
	     LayeredPat{varPat=varPat,
			expPat=ConstraintPat{pattern=expPat,
					     constraint=constraint}}
            | pat => pat)
  | lay (MarkPat(x,_),y) = lay (x,y)
  | lay p = lay2 p

val layered = lay

(* sequence of declarations *)
fun makeSEQdec (SeqDec a, endpos1, SeqDec b, endpos2) = SeqDec(a@b)
  | makeSEQdec (SeqDec a, endpos1, b, endpos2) = SeqDec(a@[(b, endpos2)])
  | makeSEQdec (a, endpos1, SeqDec b, endpos2) = SeqDec((a, endpos1)::b)
  | makeSEQdec (a, endpos1, b, endpos2) = SeqDec[(a, endpos1), (b, endpos2)]


fun QuoteExp s = ()
fun AntiquoteExp e = ()

  (***************************************************************************)

end (* structure *)


