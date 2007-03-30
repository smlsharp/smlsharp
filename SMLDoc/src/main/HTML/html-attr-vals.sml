(**
 * This structure is necessary since the attrs type is used in the parser,
 * and there is no way to get it into the parser's signature.
 *
 * @author (c) 1996 AT&T Research.
 * @version $Id: html-attr-vals.sml,v 1.2 2004/10/20 03:33:57 kiyoshiy Exp $
 *)
structure HTMLAttrVals =
  struct

  (* support for building elements that have attributes *)
    datatype attr_val
      = NAME of string          (* [a-zA-Z.-]+ *)
      | STRING of string        (* a string enclosed in "" or '' *)
      | IMPLICIT

    type attrs = (string * attr_val) list

  end;
