(**
 *
 * path representation.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PATH.sig,v 1.10 2008/03/24 05:45:50 bochao Exp $
 *)
signature PATH =
sig

  (***************************************************************************)

  datatype path =        
           PUsrStructure of string * path
         | PSysStructure of string * path
         | NilPath

  (***************************************************************************)

(*  val topStrID : id 

  val topStrName : string

  val topStrPath : path
*)
  val externStrName : string

  
  val externPath : path

  val isExternPath : path -> bool

  val pathToString : path -> string

  val usrPathToString : path -> string

  val pathToList : path -> string list

(*  val pathFromLongId : string list -> path*)

  val appendUsrPath : path * string -> path

  val appendSysPath : path * string -> path

  val joinPath : path * path -> path

  val getLastElementOfPath : path -> string

  val getParentPath : path -> path

  val getTailPath : path -> path

  val pathToUsrPath : path -> path

  val removeCommonPrefix : path * path -> path * path

  val isPrefix : {path : path, prefix : path} -> bool
(*  val hideTopStructure : path -> path *)

  val comparePathByName : path * path-> bool

  val format_pathWithDotend
      : path -> SMLFormat.FormatExpression.expression list

  val format_pathWithoutDotend
      : path -> SMLFormat.FormatExpression.expression list
end
