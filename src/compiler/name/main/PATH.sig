(**
 *
 * path representation.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PATH.sig,v 1.6 2006/02/27 06:26:14 bochao Exp $
 *)
signature PATH =
sig

  (***************************************************************************)

  type id = ID.id

  datatype path = NilPath | PStructure of id * string * path

  (***************************************************************************)

  val topStrID : id

  val topStrName : string

  val topStrPath : path

  val localizedConstrainedStrName : string

  val localizedConstrainedStrID : id

  val pathToString : path -> string

(*  val pathFromLongId : string list -> path*)

  val appendPath : path * id * string -> path

  val getLastElementOfPath : path -> {id : id, name : string}

  val getParentPath : path -> path

  val removeCommonPrefix : path * path -> path * path

  val hideTopStructure : path -> path

  val hideLocalizedConstrainedStructure : path -> path

  val comparePathByName : path * path-> bool

  val format_pathWithDotend
      : path -> SMLFormat.FormatExpression.expression list

  val format_pathWithoutDotend
      : path -> SMLFormat.FormatExpression.expression list

  (***************************************************************************)

end
