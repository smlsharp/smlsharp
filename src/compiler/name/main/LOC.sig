(**
 * Copyright (c) 2006, Tohoku University.
 * location in the source code.
 * @author YAMATODANI Kiyoshi
 * @version $Id: LOC.sig,v 1.4 2006/02/18 16:04:06 duchuu Exp $
 *)
signature LOC =
sig

  (***************************************************************************)

  eqtype pos
  type loc = pos * pos

  (***************************************************************************)

  val noloc : loc
  val nopos : pos
  val makePos : {fileName : string, line : int, col : int} -> pos
  val mergeLocs : loc * loc -> loc
  val fileNameOfPos : pos -> string
  val lineOfPos : pos -> int
  val colOfPos : pos -> int
  val format_head_pos : pos -> SMLFormat.FormatExpression.expression list
  val format_tail_pos : pos -> SMLFormat.FormatExpression.expression list
  val format_loc : pos * pos -> SMLFormat.FormatExpression.expression list

  (***************************************************************************)

end
