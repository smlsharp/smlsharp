(**
 *  documentation comment.
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: DocComment.sml,v 1.3 2005/11/03 07:34:54 kiyoshiy Exp $
 *)
structure DocComment =
struct

  (***************************************************************************)

  (*% *)
  type id = string list

  (*% *)
  datatype paramPattern =
           IDParamPat of string
         | TupleParamPat of paramPattern list
         | RecordParamPat of (string * paramPattern) list

  (*% *)
  datatype tag =
           AuthorTag of string
         | ContributorTag of string
         | CopyrightTag of string
         | ExceptionTag of id * string
         | ParamTag of string * string
         | ParamsTag of paramPattern list
         | ReturnTag of string
         | SeeTag of string
         | VersionTag of string

  (*% *)
  type docComment = string * string * tag list

  (***************************************************************************)

end